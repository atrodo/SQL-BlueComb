package SQL::BlueComb::SQL;

use strict;
use v5.12;

use Moo;
use Types::Standard qw/:all/;

has stmt => (
  is => 'ro',
  isa => Str,
  required => 1,
);

has binds => (
  is => 'ro',
  isa => ArrayRef,
  required => 1,
);

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
