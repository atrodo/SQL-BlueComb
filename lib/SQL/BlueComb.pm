package SQL::BlueComb;

use strict;
use v5.12;
our $VERSION = '0.1';

use Carp;

use Moo;
use Types::Standard qw/:all/;
use Try::Tiny;

use SQL::BlueComb::Select;

has sql_gen_target => (
  is => 'rwp',
  isa => Str,
);

sub base_pkg
{
  my $self = shift;
  my $pkg = shift;

  my $class = ref $self;

  if (!try { $class->isa(__PACKAGE__) } )
  {
    croak "Invalid subclass of SQL::BlueComb: $class";
  }

  $class .= "::$pkg"
    if defined $pkg;

  return $class;
}

sub search
{
  my $self = shift;

  my $args = scalar @_ > 1 ? { @_} : shift;

  my $class = $self->base_pkg('Select');

  return $class->new(%$args, -bluecomb => $self);
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
