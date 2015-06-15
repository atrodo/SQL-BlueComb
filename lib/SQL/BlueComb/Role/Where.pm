package SQL::BlueComb::Role::Where;

use strict;
use v5.12;

use Carp;

use Moo::Role;
use Types::Standard qw/:all/;

with 'SQL::BlueComb::Role::Build';

has where => (
  is      => 'rwp',
  isa     => HashRef,
  default => sub { {} },
);

sub BUILD
{
  my $self = shift;
  my $args = shift;

  foreach my $arg ( keys %$args )
  {
    if ( $arg =~ m/^-/xms && exists $self->{ substr $arg, 1 } )
    {
      delete $args->{$arg};
    }
  }

  $self->_set_where( { %$args, %{ $self->where }, } );

  return;
}

sub gen_where
{
  my $self   = shift;
  my $tables = shift // croak 'gen_where requires a table list';

  croak "gen_where requires \$tables to be an arrayref"
    unless ref $tables eq "ARRAY";

  my %table_cache = map { $_->{alias} => $_ } @$tables;

  # TODO
  our $current_table;

  # Internal subs, because closure
  my $generate;
  my $add_table;

  my %metagen;

  my %refgen = (
    '' => sub
    {
      my $k = shift;
      my $v = shift;

      if ( !defined $v )
      {
        return ("$k IS NULL");
      }

      return ( "$k = ?", $v );
    },

    SCALAR => sub { ... },

    ARRAY => sub
    {
      my $k = shift;
      my $v = shift;

      # Make a copy, so we don't change the original
      $v = [@$v];

      if ( uc $k eq 'OR' || uc $k eq 'AND' )
      {
        my ( $s, @b ) = $generate->( $k, @$v );
        if ($s)
        {
          $s = "( $s )";
        }
        return ( $s, @b );
      }

      my $joiner = 'OR';

      if ( @$v && $v->[0] =~ m/^-/xms )
      {
        my $op = uc $v->[0];
        if ( $op eq 'OR' || $op eq 'AND' )
        {
          shift @$v;
          $joiner = $op;
        }
      }

      if ( scalar @$v == 0 )
      {
        return ("1=0");
      }

      return ( '(' . join( " $joiner ", map {"$k = ?"} @$v ) . ')' ), @$v;
    },

    HASH => sub
    {
      my $k = shift;
      my $v = shift;

      if ( $k eq 'or' || $k eq 'and' )
      {
        my ( $s, @b ) = $generate->( $k, %$v );
        if ($s)
        {
          $s = "( $s )";
        }
        return ( $s, @b );
      }

      if ( !%$v )
      {
        return ("1=0");
      }

      my @expr;
      my @bind;

      foreach my $op ( keys %$v )
      {
        my $rhs = $v->{$op};

        if (exists $metagen{$op} && ref $rhs eq '')
        {
          if ($rhs)
          {
            my $gen = $metagen{$op};
            return $gen->( $k, $v );
          }
          
          next;
        }

        $rhs = [$rhs]
            if ref $rhs ne "ARRAY";

        push @bind, @$rhs;

        my $ph = join( ", ", map {"?"} @$rhs );

        if ( $op =~ m/^\w/xms || scalar @$rhs > 1 )
        {
          $ph = "($ph)";
        }
        push @expr,
              ( $op =~ m/^-(\w+)$/xms ) ? "$k $1 $ph"
            : ( $op =~ m/^(\W+)$/xms )  ? "$k $1 $ph"
            :                             "$k = $op $ph";
      }

      return ( join( " AND ", @expr ), @bind );
    },

    CODE    => sub {...},
    REF     => sub {...},
    GLOB    => sub {...},
    LVALUE  => sub {...},
    FORMAT  => sub {...},
    IO      => sub {...},
    VSTRING => sub {...},
    Regexp  => sub {...},

  );

  %metagen = (
    -or => sub
    {
      my $k = shift;
      my $v = shift;

      my $gen = $refgen{ ref $v };
      return $gen->( 'or', $v );
    },
    -and => sub
    {
      my $k = shift;
      my $v = shift;

      my $gen = $refgen{ ref $v };
      return $gen->( 'and', $v );
    },
    -join => sub
    {
      my $k = shift;
      my $v = shift;

      if (ref $v eq 'ARRAY')
      {
        JOINLIST:
        {
          foreach my $item (@$v)
          {
            last JOINLIST
              if ref $item ne 'HASH';
          }

          my @expr;
          my @bind;
          foreach my $join (@$v)
          {
            my ($s, @b) = $metagen{-join}->($k, $join);
            push @expr, $s if $s;
            push @bind, @b;
          }
          return ( join( " AND ", @expr ), @bind );
        }
      }

      my @clauses
          = ref $v eq 'HASH'  ? %$v
          : ref $v eq 'ARRAY' ? @$v
          :                     confess "Cannot join using " . ref($v);

      my %given_keys = @clauses;

      $given_keys{-from} = $k
        if $k ne '-from' && !exists $given_keys{-from};

      delete $given_keys{-join};

      my $from  = delete $given_keys{-from};
      my $using = delete $given_keys{-using};
      my $on    = delete $given_keys{-on};
      my $outer = delete $given_keys{-outer};

      croak "A join ($from) requires -from"
          unless defined $from;

      croak "A join ($from) requires -using or -on"
          if !defined($using) && !defined($on);

      $add_table->(from => $from, using => $using, on => $on, outer => $outer, );
      local $current_table = $from;

      my @tmp = @clauses;
      @clauses = ();
      
      while (@tmp)
      {
        my $k = shift @tmp;
        my $v = shift @tmp;

        push(@clauses, $k, $v)
          if exists $given_keys{$k};
      }

      return $generate->( ref $v, @clauses);
    },
    -ident => sub
    {
      my $k = shift;
      my $v = shift;

      return ("$k = " . $v->{-ident});
    },
  );

  $add_table = sub
  {
    my %args  = @_;
    my $from  = $args{from};
    my $using = $args{using};
    my $on    = $args{on};
    my $outer = $args{outer};

    croak "A join cannot have both -using and -on"
        if defined $using && defined $on;
    
    my $alias = $from;
    my $alias_cnt = 0;

    while (exists $table_cache{$alias})
    {
      $alias = $from . "_" . $alias_cnt++;
    }

    my $table = { from => $from, alias => $alias, outer => $outer, };

    $table->{using} = $using
      if defined $using;

    if (defined $on)
    {
      my ( $s, @b ) = $generate->( ref $on, $on );
      $table->{on} = $s;
      $table->{bind} = [@b];
    }

    push @$tables, $table;
    $table_cache{$alias} = $table;

    return $alias;
  };

  $generate = sub
  {
    my $mode = shift;
    my @in_where
        = ref $_[0] eq 'ARRAY' ? @{ $_[0] }
        : ref $_[0] eq 'HASH'  ? %{ $_[0] }
        :                        @_;
    $mode
        = $mode eq 'ARRAY' ? 'OR'
        : $mode eq 'HASH'  ? 'AND'
        :                    uc $mode;


    my @where;
    my @bind;

    croak "Invalid mode: $mode"
        unless $mode eq 'AND' || $mode eq 'OR';

CLAUSE:
    while ( @in_where >= 2 )
    {
      my $k = shift @in_where;
      my $v = shift @in_where;

      my ( $s, @b );

      if ( $k =~ m/^-/xms )
      {
        my $gen = $metagen{$k};

        croak "Unknown meta key: $k"
            if !defined $gen;

        ( $s, @b ) = $gen->( $k, $v );
      }
      else
      {
        my $gen = $refgen{ ref $v };
        ( $s, @b ) = $gen->( $k, $v );
      }

      if ($s)
      {
        push @where, $s;
        push @bind,  @b;
      }
    }

    croak
        if @in_where;

    my $stmt = join( " $mode ", @where );

    return ( $stmt, @bind );
  };

  my ( $stmt, @bind ) = $generate->( 'and', %{ $self->where } );

  $stmt = " WHERE $stmt"
      if $stmt;

  return ( $stmt, @bind );
}

1;

__END__

=encoding utf-8

=head1 NAME

SQL::BlueComb - Blah blah blah

=head1 SYNOPSIS

  use SQL::BlueComb;

=head1 DESCRIPTION

SQL::BlueComb is

=head1 AUTHOR

Jon Gentle E<lt>cpan@atrodo.orgE<gt>

=head1 COPYRIGHT

Copyright 2015- Jon Gentle

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
