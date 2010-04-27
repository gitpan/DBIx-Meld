#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use DBIx::Meld;

my $meld = DBIx::Meld->new( 'dbi:SQLite:dbname=t/test.db', '', '' );

$meld->run(sub{
    my ($dbh) = @_;

    $dbh->do('DROP TABLE IF EXISTS users');
    $dbh->do('CREATE TABLE users (user_id NUMBER, user_name TEXT, email TEXT)');
});

$meld->insert('users', {user_id=>1, user_name=>'one',    email=>'one@example.com'});
$meld->insert('users', {user_id=>2, user_name=>'twoBAD', email=>'two@example.com'});
$meld->insert('users', {user_id=>3, user_name=>'three',  email=>'three@example.com'});
$meld->insert('users', {user_id=>4, user_name=>'BAD',    email=>'four@example.com'});

$meld->delete( 'users', { user_id=>4 } );
$meld->update( 'users', { user_name=>'two' }, { user_id=>2 } );

is_deeply(
    $meld->array_row( 'users', ['user_name', 'email'], {user_id => 3} ),
    [ 'three', 'three@example.com' ],
    'array_row',
);

is_deeply(
    $meld->hash_row( 'users', '*', {user_id => 2} ),
    { user_id=>2, user_name=>'two', email=>'two@example.com' },
    'hash_row',
);

is_deeply(
    $meld->array_of_array_rows('users', 'user_name', {user_id => {'>=' => 2}}, {order_by => 'user_id DESC'}),
    [
        ['three'],
        ['two'],
    ],
    'array_of_array_rows',
);

is_deeply(
    $meld->array_of_hash_rows('users', '*', {user_id => {'<' => 3}}, {order_by => 'user_id'}),
    [
        {user_id=>1, user_name=>'one',   email=>'one@example.com'},
        {user_id=>2, user_name=>'two',   email=>'two@example.com'},
    ],
    'array_of_hash_rows',
);

is_deeply(
    $meld->hash_of_hash_rows('user_id', 'users'),
    {
        1 => {user_id=>1, user_name=>'one',   email=>'one@example.com'},
        2 => {user_id=>2, user_name=>'two',   email=>'two@example.com'},
        3 => {user_id=>3, user_name=>'three', email=>'three@example.com'},
    },
    'hash_of_hash_rows',
);

is( $meld->count('users'), 3, 'count' );

is_deeply(
    $meld->column('users', 'user_id', {}, {order_by => 'user_id'}),
    [1, 2, 3],
    'column',
);

{
    my ($sth, @bind) = $meld->select_sth('users', ['user_id', 'user_name']);
    $sth->execute( @bind );
    $sth->bind_columns( \my( $user_id, $user_name ) );

    my $users = {};
    while ($sth->fetch()) {
        $users->{$user_id} = $user_name;
    }

    is_deeply(
        $users,
        { 1=>'one', 2=>'two', 3=>'three' },
        'select_sth',
    );
}

{
    my $sth;
    foreach my $user_id (4, 5, 6) {
        my $fields = {user_id=>$user_id, user_name=>"user$user_id", email=>'BAD'};
        $sth ||= $meld->insert_sth('users', $fields);
        $sth->execute( $meld->bind_values($fields) );
    }

    is_deeply(
        $meld->array_of_array_rows('users', ['user_id', 'user_name', 'email'], {user_id=>{'>' => 3}}, {order_by => 'user_id'}),
        [
            [4, 'user4', 'BAD'],
            [5, 'user5', 'BAD'],
            [6, 'user6', 'BAD'],
        ],
        'insert_sth',
    );
}

done_testing;
1;
