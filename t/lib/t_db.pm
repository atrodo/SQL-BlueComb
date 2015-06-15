package t_db;
use DBI;

unlink "t.sqlite" if -e "t.sqlite";
my $dbh = DBI->connect("dbi:SQLite:dbname=t.sqlite","","");
#my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:','','');

sub get
{
  return $dbh;
}

my @stmts = (
'CREATE TABLE person (person_id INTEGER PRIMARY KEY, username, email);',

'CREATE TABLE task (task_id INTEGER PRIMARY KEY, details);',
'CREATE TABLE person_task (person_id, task_id, priority, start_ts, complete_ts);',

'CREATE TABLE grp (grp_id INTEGER PRIMARY KEY, name);',
'CREATE TABLE person_grp (person_id, grp_id);',

'CREATE TABLE request (request_id INTEGER PRIMARY KEY, request_person_id, task_id, grp_id);',
'CREATE TABLE likes (likes_id INTEGER PRIMARY KEY, task_id, person_id, at_ts);',


'INSERT INTO person VALUES (1, "alice", "alice@example.com");',
'INSERT INTO person VALUES (2, "bob", "bob@example.com");',
'INSERT INTO person VALUES (3, "carol", "carol@example.com");',
'INSERT INTO person VALUES (4, "dave", "dave@example.com");',
'INSERT INTO person VALUES (5, "esther", null);',

'INSERT INTO task VALUES (1, "Pay Bills");',
'INSERT INTO task VALUES (2, "Feed Cats");',
'INSERT INTO task VALUES (3, "Write Tests");',
'INSERT INTO task VALUES (4, "Add Comments");',
'INSERT INTO task VALUES (5, "Install CPAN");',
'INSERT INTO task VALUES (6, "Make Widget");',
'INSERT INTO task VALUES (7, "Do Things");',
'INSERT INTO task VALUES (8, "Get Milk");',

'INSERT INTO person_task VALUES (1, 1, 1, "2015-04-01 10:29:00", null);',
'INSERT INTO person_task VALUES (5, 2, 1, "2015-04-01 10:29:00", "2015-04-01 11:38:00");',
'INSERT INTO person_task VALUES (2, 5, 1, "2015-04-01 10:29:00", null);',
'INSERT INTO person_task VALUES (1, 7, 2, "2015-04-01 10:29:00", null);',

'INSERT INTO grp VALUES (1, "Programmers");',
'INSERT INTO grp VALUES (2, "Family");',

'INSERT INTO person_grp VALUES (1, 1);',
'INSERT INTO person_grp VALUES (2, 1);',
'INSERT INTO person_grp VALUES (1, 2);',
'INSERT INTO person_grp VALUES (4, 2);',
'INSERT INTO person_grp VALUES (5, 2);',

'INSERT INTO request VALUES (1, 3, 3, 1);',
'INSERT INTO request VALUES (2, 4, 3, 1);',
'INSERT INTO request VALUES (3, 6, 3, 1);',
'INSERT INTO request VALUES (4, 8, 1, 2);',

'INSERT INTO likes VALUES (1, 3, 3, "2015-04-01 10:31:00");',
'INSERT INTO likes VALUES (2, 4, 3, "2015-04-01 10:31:15");',
'INSERT INTO likes VALUES (3, 5, 3, "2015-04-01 10:31:21");',
'INSERT INTO likes VALUES (4, 6, 3, "2015-04-01 10:31:28");',
'INSERT INTO likes VALUES (5, 3, 3, "2015-04-01 10:31:00");',
'INSERT INTO likes VALUES (6, 5, 1, "2015-04-01 11:21:00");',
'INSERT INTO likes VALUES (8, 6, 4, "2015-04-01 14:31:00");',
'INSERT INTO likes VALUES (9, 7, 4, "2015-04-01 14:31:22");',
'INSERT INTO likes VALUES (10, 8, 4, "2015-04-01 16:31:00");',
);
$dbh->do($_) foreach @stmts;

1;
