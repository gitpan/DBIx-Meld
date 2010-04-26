package DBIx::Meld;
BEGIN {
  $DBIx::Meld::VERSION = '0.06';
}
use Moose;
use namespace::autoclean;

=head1 NAME

DBIx::Meld - An ORMish amalgamation.

=head1 SYNOPSIS

    # Use the same argument as DBI:
    my $meld = DBIx::Meld->new(
        $dsn,
        $user,
        $pass,
        $attrs, # optional
    );
    
    # Or pass a pre-built DBIx::Connector object:
    my $meld = DBIx::Meld->new( connector => $connector );
    
    # Several DBIx::Connector methods are proxied:
    $meld->txn(sub{ ... });
    $meld->run(sub{ ... });
    $meld->svp(sub{ ... });
    my $dbh = $meld->dbh();
    
    # If you need access to any other DBIx::Connector methods,
    # go through the connector() accessor:
    if ($meld->connector->connected()) { ... }
    
    my $abstract = $meld->abstract(); # The SQL::Abstract::Limit object.
    
    $meld->insert(
        'users',                                            # table name
        { user_name=>'bob2003', email=>'bob@example.com' }, # fields to insert
        { returning => 'user_id' },                         # extra clauses
    );
    
    $meld->update(
        'users',                 # table name
        { phone => '555-1234' }, # fields to update
        { user_id => $uid },     # where clause
    );
    
    $meld->delete(
        'users',             # table name
        { user_id => $uid }, # where clause
    );
    
    my $user = $meld->array_row(
        'users',                                  # table name
        ['user_id', 'created', 'email', 'phone'], # fields to retrieve
        { user_name => $uname },                  # where clause
    );
    
    my $user = $meld->hash_row(
        'users',                    # table name
        ['user_id', 'created'],     # fields to retrieve
        { user_name => 'bob2003' }, # where clause
    );
    
    my $disabled_users = $meld->array_of_array_rows(
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        { order_by => 'status' },      # extra clauses
    );
    print $disabled_users->[2]->[1];
    
    my $disabled_users = $meld->array_of_hash_rows(
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        { order_by => 'user_name' },   # extra clauses
    );
    print $disabled_users->[2]->{email};
    
    my $disabled_users = $meld->hash_of_hash_rows(
        'user_name',                   # column to index the hash by
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        { limit => 20 },               # extra clauses
    );
    print $disabled_users->{jsmith}->{email};
    
    my $enabled_users_count = $meld->count(
        'users',        # table name
        { status => 1}, # where clause
    );
    
    my $user_ids = $meld->column(
        'users',                            # table name
        'user_id',                          # column to retrieve
        { status => 1},                     # where clause
        { limit=>10, order_by=>'user_id' }, # extra clauses
    );
    
    my ($sth, @bind) = $meld->select_sth(
        'users',                  # table name
        ['user_name', 'user_id'], # fields to retrieve
        {status => 1 },           # where clause
    );
    $sth->execute( @bind );
    $sth->bind_columns( \my( $user_name, $user_id ) );
    while ($sth->fetch()) { ... }
    
    my $insert_sth;
    foreach my $user_name (qw( jsmith bthompson gfillman )) {
        my $fields = {
            user_name => $user_name,
            email     => $user_name . '@mycompany.com',
        };
    
        $insert_sth ||= $meld->insert_sth(
            'users', # table name
            $fields, # fields to insert
        );
    
        $insert_sth->execute(
            $meld->bind_values( $fields ),
        );
    }
    
    my $rs = $meld->resultset('users');
    
    my $formatter = $meld->datetime_formatter();
    print $formatter->format_date( DateTime->now() );
    
    print $meld->format_datetime( DateTime->now() );
    
    print $meld->format_date( DateTime->now() );
    
    print $meld->format_time( DateTime->now() );

=head1 DESCRIPTION

This module combines the features of L<DBIx::Connector>, L<SQL::Abstract>,
and the various DateTime::Format modules, with some of the design concepts
of L<DBIx::Class>.

=head1 EXPERIMENTAL

This module is in a bit of an expirimental state.  It hasn't yet been used
in any large projects, some bits still need automated tests, and the API
may still be changing before this module can be called stable.

That being said, the majority of the features that this module provides
will not be changing.  In addition, this module is a light-weight wrapper
around code that has been stable for years and has regular production use,
so don't be too worried.

If you have a success story (or fail story) of using this module, or any
other feedback, then please let the author know.

=head1 WHY

When writing raw DBI code there is a huge lacking of core features that
other more advanced libraries provide, such as L<DBIx::Class>.  These
missing features are:

=over

=item * Robust connection and transation handling.

=item * Greatly reduced need to write raw SQL.

=item * Database independent date and time handling.

=item * Ability to progressively construct queries using resultsets.

=back

So, the intent of this module is to fill this gap.  With this module you
are still dealing with low-level DBI calls, yet you still get many of these
great benefits.

Even with this module you will often need to write raw DBI code, as DBIx::Meld
isn't meant to be the one tool that rules them all.  Instead, DBIx::Meld is
meant to simplify the majority of the DBI work you do, but not all of it.

=head1 YAORM

This module is not "Yet Another ORM".  The point of this module is that
*it is not an ORM*.  It is ORMish because it has some aspects that act
similarly to the ORMs available to us today.  But, that is as deep as it
goes.

If you want an ORM, try out L<DBIx::Class>.  It is superb.

=head1 TRAITS

=head2 Connector

This traite provides all of L<DBIx::Connector>'s methods as methods on DBIx::Meld.
Ready more at L<DBIx::Meld::Traits::Connector>.

=cut

with 'DBIx::Meld::Traits::Connector';

=head2 Abstract

This trait provides access to most of L<SQL::Abstract>'s methods as methods
on DBIx::Meld.  Ready more at L<DBIx::Meld::Traits::Abstract>.

=cut

with 'DBIx::Meld::Traits::Abstract';

=head2 DateTimeFormat

This trait provides access to the appropriate DateTime::Format module and
provides helper methods on DBIx::Meld.  Read more at L<DBIx::Meld::Traits::DateTimeFormat>.

=cut

with 'DBIx::Meld::Traits::DateTimeFormat';

=head2 ResultSet

This trait provides the resultset() method which, when given a table
name, returns an L<DBIx::Meld::ResultSet> object.  Read more at
L<DBIx::Meld::Traits::ResultSet>.

=cut

with 'DBIx::Meld::Traits::ResultSet';

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 TODO

=over

=item * Support GROUP BY, HAVING, and LIMIT (and Data::Page?) clauses.

=item * Integrate DBIC's well-tested auto-generated ID retrieval code.  This can be tricky
since each DB does it in a different way (/looks at Oracle).  Then, insert() can
return that ID.

=item * Support pluggable traits so that other CPAN authors can release distros that easly
plug in and add functionality.

=item * Add an update_sth() method to the SQLAbstract trait.  This is difficult since it
appears that SQL::Abstract->values() only works with selects, inserts, and deletes.

=item * Verify how DBI errors are propogated back to the user so that the error is useful
and points to the area of code that best helps the user understand and fix the issue.

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

