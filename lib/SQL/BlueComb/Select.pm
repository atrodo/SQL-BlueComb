package SQL::BlueComb::Select;

use strict;
use v5.12;

use SQL::BlueComb::SQL;

use Moo;
use Types::Standard qw/:all/;

with 'SQL::BlueComb::Role::Build';
with 'SQL::BlueComb::Role::Where';
with 'SQL::BlueComb::Role::WithBlueComb';

has from => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has select => (
  is => 'rwp',
  isa => ArrayRef[Str],
  default => sub { ['*'] },
);

sub count
{
  my $self = shift;

  my $result = { %$self, select => ['count(*)'], };
  bless $result, ref $self;

  return $result;
}

sub sql
{
  my $self = shift;

  my $stmt = "";
  my $from = { from => $self->from, alias => $self->from, };
  my $tables = [ $from ];
  my ($where, @bind) = $self->gen_where($tables);

  $stmt .= "SELECT ";
  $stmt .= join(", ", @{ $self->select });
  $stmt .= " FROM ";

  foreach my $table ( @$tables )
  {
    my $is_join = exists $table->{using} || exists $table->{on};

    if (!$is_join)
    {
      $stmt .= ", "
        if $table ne $from;
    }
    else
    {
      $stmt .= " LEFT "
        if $table->{outer};
      $stmt .= " JOIN ";
    }

    $stmt .= $table->{from};
    $stmt .= " AS " . $table->{alias};

    if (exists $table->{using})
    {
      $stmt .= " USING (" . $table->{using} . ")";
    }

    if (exists $table->{on})
    {
      $stmt .= " ON (" . $table->{on} . ")";
    }

    push @bind, @{ $table->{bind} }
      if defined $table->{bind};
  }

  $stmt .= $where;

  my $sql_pkg = $self->bluecomb->base_pkg('SQL');
  return $sql_pkg->new(stmt => $stmt, binds => \@bind);
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

This is free software. You may redistribute copies of it under the terms of the Artistic License 2 as published by The Perl Foundation.

=head1 SEE ALSO

=cut
