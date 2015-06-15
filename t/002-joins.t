use strict;
use Test::More;
use SQL::BlueComb;

use Data::Dumper;

use lib 't/lib';
use t_db;

my $dbh = t_db::get();
my ( $sth, $rs, $rs2 );

$dbh->{RaiseError} = 1;

sub dbh_exec
{
  my $rs  = shift;
  my $sql = $rs->sql;

  my $sth = $dbh->prepare( $sql->stmt );

  $sth->execute( @{ $sql->binds } );

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
    -join => {
      -from  => 'person_task',
      -using => 'person_id',
    },
  }
);

is( count($rs), 4, "Can count with a basic join" );

$rs = $bc->search(
  {
    -from => 'person',
    person_task => {
      -join  => 1,
      -using => 'person_id',
    },
  }
);

is( count($rs), 4, "Can count from a named join" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => {
      -from  => 'person_task',
      -using => 'person_id',
      -outer => 1,
    },
  }
);

is( count($rs), 6, "Can count from an outer join" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => {
      -from     => 'person_task',
      -using    => 'person_id',
      person_id => 1,
    },
  }
);

is( count($rs), 2, "Can count with a where clause in a join" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => {
      -from  => 'person_task',
      -using => 'person_id',
    },
    person_id => 1,
  }
);

is( count($rs), 2, "Can count with a where and a join" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => {
      -from  => 'person_task',
      -using => 'person_id',
      -join  => {
        -from  => 'task',
        -using => 'task_id',
      },
    },
  }
);

is( count($rs), 4, "Can count with a 2-level nested join" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => {
      -from => 'task',
      -on   => { 'person.person_id' => { -ident => 'task.task_id', } },
    },
  }
);

is( count($rs), 5, "Can use an on clause" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => {
      -from => 'task',
      -on   => {
        'person.person_id' => { -ident => 'task.task_id' },
        'person.username'  => 'alice',
      },
    },
  }
);

is( count($rs), 1, "Can use a >1 item on clause" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => [
      {
        -from  => 'person_task',
        -using => 'person_id',
      },
      {
        -from  => 'person_grp',
        -using => 'person_id',
      },
    ],
  }
);

is( count($rs), 6, "Can use an array join" );

$rs = $bc->search(
  {
    -from => 'person',
    -join => [
      {
        -from  => 'person_task',
        -using => 'person_id',
        -join  => {
          -from  => 'task',
          -using => 'task_id',
        },
      },
      {
        -from  => 'person_grp',
        -using => 'person_id',
      },
      {
        -from => 'request',
        -on   => {
          'person.person_id' => { -ident => 'request.request_person_id' },
        },
        -join => [
          {
            -from  => 'task',
            -using => 'task_id',
          },
          {
            -from  => 'grp',
            -using => 'grp_id',
          },
        ],
      },
      {
        -from  => 'likes',
        -using => 'person_id',
        -join  => {
          -from  => 'task',
          -using => 'task_id',
        },
      },
    ],
  }
);

is( count($rs), 0, "Can join multiple tables" );

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
