requires 'perl', '5.012000';

requires 'Moo', '2.000';
requires 'Types::Standard';
requires 'Try::Tiny';
requires 'List::AllUtils';

on test => sub {
    requires 'Test::More', '0.96';
    requires 'DBD::SQLite';
};
