package DBIx::Meld::Traits::Abstract;
BEGIN {
  $DBIx::Meld::Traits::Abstract::VERSION = '0.09';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::Abstract - Melds SQL::Abstract with DBIx::Meld.

=head1 DESCRIPTION

This trait is a wrapper around L<SQL::Abstract::Limit>, which itself is a lightweight
wrapper around L<SQL::Abstract> by automatically calling prepare() and execute()
on the generated SQL.

The arguments to the various methods are identical to the SQL::Abstract methods,
excepts for the extra clauses RETURNING, ORDER BY, LIMIT, and OFFSET.  In these
cases the format of the argument has been changed to be a hashref so that more
clauses can be added in the future, such as GROUP BY, HAVING, etc.

=cut

use SQL::Abstract::Limit;

=head1 ATTRIBUTES

=head2 abstract

The L<SQL::Abstract::Limit> (a subclass of L<SQL::Abstract> that adds LIMIT/OFFSET support)
object.

=cut

has 'abstract' => (
    is => 'ro',
    isa => 'SQL::Abstract::Limit',
    lazy_build => 1,
);
sub _build_abstract {
    my ($self) = @_;

    return $self->connector->run(sub{
        my ($dbh) = @_;

        return SQL::Abstract::Limit->new(
            limit_dialect => $dbh,
        );
    });
}

sub _dbi_execute {
    my ($self, $dbh_method, $sql, $bind, $dbh_attrs) = @_;

    return $self->connector->run(sub{
        my ($dbh) = @_;
        my $sth = $dbh->prepare_cached( $sql );
        if ($dbh_method eq 'do') {
            $sth->execute( @$bind );
        }
        else {
            return $dbh->$dbh_method( $sth, $dbh_attrs, @$bind );
        }
        return;
    });
}

sub _dbi_prepare {
    my ($self, $sql) = @_;

    return $self->connector->run(sub{
        my ($dbh) = @_;
        return $dbh->prepare_cached( $sql );
    });
}

sub _do_select {
    my ($self, $table, $fields, $where, $clauses) = @_;

    return $self->abstract->select(
        $table, $fields, $where,
        $clauses->{order_by},
        $clauses->{limit},
        $clauses->{offset},
    );
}

=head1 METHODS

=head2 insert

    $meld->insert(
        'users',                                            # table name
        { user_name=>'bob2003', email=>'bob@example.com' }, # fields to insert
        { returning => 'user_id' },                         # extra clauses
    );

This accepts the same arguments as L<SQL::Abstract>'s insert() method
accepts.

=cut

sub insert {
    my ($self, $table, $fields, $clauses) = @_;
    my ($sql, @bind) = $self->abstract->insert( $table, $fields, $clauses );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 update

    $meld->update(
        'users',                 # table name
        { phone => '555-1234' }, # fields to update
        { user_id => $uid },     # where clause
    );

This accepts the same arguments as L<SQL::Abstract>'s update() method
accepts.

=cut

sub update {
    my ($self, $table, $fields, $where) = @_;
    my ($sql, @bind) = $self->abstract->update( $table, $fields, $where );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 delete

    $meld->delete(
        'users',             # table name
        { user_id => $uid }, # where clause
    );

This accepts the same arguments as L<SQL::Abstract>'s delete() method
accepts.

=cut

sub delete {
    my ($self, $table, $where) = @_;
    my ($sql, @bind) = $self->abstract->delete( $table, $where );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 array_row

    my $user = $meld->array_row(
        'users',                                  # table name
        ['user_id', 'created', 'email', 'phone'], # fields to retrieve
        { user_name => $uname },                  # where clause
    );

=cut

sub array_row {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return [ $self->_dbi_execute( 'selectrow_array', $sql, \@bind ) ];
}

=head2 hash_row

    my $user = $meld->hash_row(
        'users',                    # table name
        ['user_id', 'created'],     # fields to retrieve
        { user_name => 'bob2003' }, # where clause
    );

=cut

sub hash_row {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return $self->_dbi_execute( 'selectrow_hashref', $sql, \@bind );
}

=head2 array_of_array_rows

    my $disabled_users = $meld->array_of_array_rows(
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        { order_by => 'status' },      # extra clauses
    );
    print $disabled_users->[2]->[1];

Returns an array ref of array refs, one for each row returned.

=cut

sub array_of_array_rows {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return $self->_dbi_execute( 'selectall_arrayref', $sql, \@bind );
}

=head2 array_of_hash_rows

    my $disabled_users = $meld->array_of_hash_rows(
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        { order_by => 'user_name' },   # extra clauses
    );
    print $disabled_users->[2]->{email};

=cut

sub array_of_hash_rows {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return $self->_dbi_execute( 'selectall_arrayref', $sql, \@bind, { Slice=>{} } );
}

=head2 hash_of_hash_rows

    my $disabled_users = $meld->hash_of_hash_rows(
        'user_name',                   # column to index the hash by
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        { limit => 20 },               # extra clauses
    );
    print $disabled_users->{jsmith}->{email};

=cut

sub hash_of_hash_rows {
    my ($self, $key, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return $self->connector->run(sub{
        my ($dbh) = @_;
        my $sth = $dbh->prepare_cached( $sql );
        return $dbh->selectall_hashref( $sth, $key, {}, @bind );
    });
}

=head2 count

    my $enabled_users_count = $meld->count(
        'users',        # table name
        { status => 1}, # where clause
    );

=cut

sub count {
    my ($self, $table, $where, @args) = @_;
    my ($sql, @bind) = $self->_do_select( $table, 'COUNT(*)', $where, @args );
    return ( $self->_dbi_execute( 'selectrow_array', $sql, \@bind ) )[0];
}

=head2 column

    my $user_ids = $meld->column(
        'users',                            # table name
        'user_id',                          # column to retrieve
        { status => 1},                     # where clause
        { limit=>10, order_by=>'user_id' }, # extra clauses
    );

=cut

sub column {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return $self->_dbi_execute( 'selectcol_arrayref', $sql, \@bind );
}

=head2 select_sth

    my ($sth, @bind) = $meld->select_sth(
        'users',                  # table name
        ['user_name', 'user_id'], # fields to retrieve
        {status => 1 },           # where clause
    );
    $sth->execute( @bind );
    $sth->bind_columns( \my( $user_name, $user_id ) );
    while ($sth->fetch()) { ... }

If you want a little more power, or want you DB access a little more
effecient for your particular situation, then you might want to get
at the select sth.

=cut

sub select_sth {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->_do_select( @args );
    return( $self->_dbi_prepare( $sql ), @bind );
}

=head2 insert_sth

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

If you're going to insert a *lot* of records you probably don't want to
be re-generating the SQL every time you call $meld->insert().

=cut

sub insert_sth {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->insert( @args );
    return $self->_dbi_prepare( $sql );
}

=head2 bind_values

This mehtod is a non-modifying wrapper around L<SQL::Abstract>'s values()
method to be used in conjunction with insert_sth().

=cut

sub bind_values {
    my ($self, $fields) = @_;
    return $self->abstract->values( $fields );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

