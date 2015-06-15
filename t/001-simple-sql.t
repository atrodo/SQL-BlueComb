use strict;
use Test::More;
use SQL::BlueComb;

use Data::Dumper;

use lib 't/lib';
use t_db;

my $dbh = t_db::get();
my ( $sth, $rs );

$dbh->{RaiseError} = 1;

sub dbh_exec
{
  my $rs  = shift;
  my $sql = $rs->sql;

  #diag Data::Dumper::Dumper($sql);

  my $sth = $dbh->prepare( $sql->stmt );

  $sth->execute( @{$sql->binds} );

  return $sth;
}

sub count
{
  my $rs = shift;
  $rs = $rs->count;

  my $sth = dbh_exec($rs);
  return ( $sth->fetchrow_array )[0];
}

my $bc = SQL::BlueComb->new;

$rs = $bc->search(
  {
    -from => 'person',
  }
);

is( count($rs), 5, "Can count from a table" );

$rs = $bc->search(
  {
    -from    => 'person',
    username => 'esther',
  }
);

is( count($rs), 1, "Defaulting to where works" );

$rs = $bc->search(
  {
    -from => 'person',
    username => [ ],
  }
);

is( count($rs), 0, "Test an edge case with an empty array" );

$rs = $bc->search(
  {
    -from => 'person',
    username => [ qw/bob esther/ ],
  }
);

is( count($rs), 2, "Using Arrays makes and lists" );

$rs = $bc->search(
  {
    -from => 'person',
    -or => [
      username => 'bob',
      username => 'esther',
    ],
  }
);

is( count($rs), 2, "Can do SQL::Abstract style OR" );

$rs = $bc->search(
  {
    -from => 'person',
    -and => [
      username => 'bob',
      username => 'esther',
    ],
  }
);

is( count($rs), 0, "Can do SQL::Abstract style AND" );

$rs = $bc->search(
  {
    -from => 'person',
    email => undef,
  }
);

is( count($rs), 1, "undef does is null" );

$rs = $bc->search(
  {
    -from => 'person',
    username => 'esther',
    person_id => { '>=' => 3 },
  }
);

is( count($rs), 1, "Can do numerical where operator" );

$rs = $bc->search(
  {
    -from => 'person',
    email => { -like => '%example.com' },
  }
);

is( count($rs), 4, "Can do a function where operation" );

done_testing;

__END__

->insert({
  -from => 'person',
});

->update({
  -from => 'person',
});

->delete({
  -from => 'person',
});

done_testing;
