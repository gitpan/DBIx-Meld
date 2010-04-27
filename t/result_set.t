#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use DBIx::Meld;

my $meld = DBIx::Meld->new( 'dbi:SQLite:dbname=t/test.db', '', '' );

$meld->run(sub{
    my ($dbh) = @_;

    $dbh->do('DROP TABLE IF EXISTS users');
    $dbh->do('CREATE TABLE users (user_id NUMBER, user_name TEXT, status NUMBER)');
});

my $users = $meld->resultset('users');
$users->insert( {user_id=>1, user_name=>'one',   status=>1} );
$users->insert( {user_id=>2, user_name=>'two',   status=>0} );
$users->insert( {user_id=>3, user_name=>'three', status=>1} );

my $on_users = $users->search({ status => 1 });
is( $on_users->table(), 'users', 'table' );
is_deeply( $on_users->where(), { status=>1 }, 'where' );

is( $on_users->search(undef, {order_by=>'user_name'})->clauses->{order_by}, 'user_name', 'order_by' );
is( $on_users->search(undef, {page=>3})->clauses->{page}, 3, 'page' );
is( $on_users->search(undef, {rows=>20})->clauses->{rows}, 20, 'rows' );

my $paged_rs = $users->search(undef, { page=>1, rows=>2, order_by=>'user_id' });
is( $paged_rs->last_page(), 2, 'last_page' );
is( $paged_rs->total_entries(), 3, 'total_entries' );

is_deeply( $paged_rs->column('user_id'), [1, 2], 'page 1' );
$paged_rs->_prep_limit();
$paged_rs = $paged_rs->search(undef, { page=>2 });
is_deeply( $paged_rs->column('user_id'), [3], 'page 2' );

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->array_row(['user_id', 'user_name']),
    ['1', 'one'],
    'array_row',
);

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->hash_row(['user_id', 'user_name']),
    { user_id => '1', user_name => 'one' },
    'hash_row',
);

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->array_of_array_rows('user_id'),
    [[1],[2],[3]],
    'array_of_array_rows',
);

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->array_of_hash_rows('user_name'),
    [{user_name=>'one'},{user_name=>'two'},{user_name=>'three'}],
    'array_of_hash_rows',
);

is_deeply(
    $users->hash_of_hash_rows('user_id', 'user_id'),
    {1=>{user_id=>1},2=>{user_id=>2},3=>{user_id=>3}},
    'hash_of_hash_rows',
);

is( $on_users->count(), 2, 'count' );

done_testing;
__END__

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
    $meld->array_of_array_rows('users', 'user_name', {user_id => {'>=' => 2}}, 'user_id DESC' ),
    [
        ['three'],
        ['two'],
    ],
    'array_of_array_rows',
);

is_deeply(
    $meld->array_of_hash_rows('users', '*', {user_id => {'<' => 3}}, 'user_id' ),
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
    $meld->column('users', 'user_id', {}, 'user_id'),
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
        $meld->array_of_array_rows('users', ['user_id', 'user_name', 'email'], {user_id=>{'>' => 3}}, 'user_id'),
        [
            [4, 'user4', 'BAD'],
            [5, 'user5', 'BAD'],
            [6, 'user6', 'BAD'],
        ],
        'insert_sth',
    );
}

{
    my $sth;
    foreach my $user_id (4, 5, 6) {
        my $where = {user_id => $user_id};
        $sth ||= $meld->delete_sth('users', $where);
        $sth->execute( $meld->bind_values($where) );
    }

    is_deeply(
        $meld->column('users', 'user_id', {}, 'user_id'),
        [ 1, 2, 3 ],
        'delete_sth',
    );
}

done_testing;
1;
