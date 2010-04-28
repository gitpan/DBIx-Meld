package DBIx::Meld;
BEGIN {
  $DBIx::Meld::VERSION = '0.09';
}
use Moose;
use namespace::autoclean;

with 'DBIx::Meld::Traits::Connector';
with 'DBIx::Meld::Traits::Abstract';
with 'DBIx::Meld::Traits::ResultSet';
with 'DBIx::Meld::Traits::DateTimeFormat';

=head1 NAME

DBIx::Meld - An ORMish amalgamation.

=head1 SYNOPSIS

    use DBIx::Meld;
    
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
of L<DBIx::Class>.  These features include robust connection and transaction
handling, greatly reduced need to write raw SQL, database independent date
and time handling, and the ability to progressively construct queries using
result sets

Note that this module is not an ORM, but is intended to be a lightweight
alternative to a full blown ORM.  If you want an ORM, try out L<DBIx::Class>.

=head1 SUPPORT

=over

=item * View/Report Bugs: L<http://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Meld>

=item * Repository: L<http://github.com/bluefeet/DBIx-Meld>

=item * Mailing List: L<http://groups.google.com/group/dbix-meld>

=back

=head1 TODO

=over

=item * Support GROUP BY and HAVING clauses.

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

=cut

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

