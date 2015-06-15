package SQL::BlueComb::Role::Build;

use strict;
use v5.12;

use Moo::Role;

around has => sub {
  my $orig = shift;
  my $name = shift;
  my %args = @_;

  if (!exists $args{init_arg})
  {
    $args{init_arg} = "-$name";
  }
  
  return $orig->($name, %args);
};

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
