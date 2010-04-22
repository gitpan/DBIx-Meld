package DBIx::Meld::Traits::SQLAbstract;
BEGIN {
  $DBIx::Meld::Traits::SQLAbstract::VERSION = '0.03';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::SQLAbstract - Melds SQL::Abstract with DBIx::Meld.

=cut

use SQL::Abstract;

=head1 ATTRIBUTES

=head2 abstract

The L<SQL::Abstract> object that is being used.

=cut

has 'abstract' => (
    is => 'ro',
    isa => 'SQL::Abstract',
    lazy_build => 1,
);
sub _build_abstract {
    return SQL::Abstract->new();
}

sub _dbi_execute {
    my ($self, $dbh_method, $sql, $bind, $dbh_attrs) = @_;

    return $self->run(sub{
        my ($dbh) = @_;
        my $sth = $dbh->prepare_cached( $sql );
        return $dbh->$dbh_method( $sth, $dbh_attrs, @$bind );
    });
}

sub _dbi_prepare {
    my ($self, $sql) = @_;

    return $self->run(sub{
        my ($dbh) = @_;
        return $dbh->prepare_cached( $sql );
    });
}

=head1 METHODS

=head2 insert

    $meld->insert(
        'users',                                            # table name
        { user_name=>'bob2003', email=>'bob@example.com' }, # fields to insert
    );

This accepts the same arguments as L<SQL::Abstract>'s insert() method
accepts.

=cut

sub insert {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->insert( @args );
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
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->update( @args );
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
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->delete( @args );
    $self->_dbi_execute( 'do', $sql, \@bind );
    return;
}

=head2 array_row

    my $user = $sweeet->array_row(
        'users',                                  # table name
        ['user_id', 'created', 'email', 'phone'], # fields to retrieve
        { user_name => $uname },                  # where clause
    );

=cut

sub array_row {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
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
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_execute( 'selectrow_hashref', $sql, \@bind );
}

=head2 array_of_array_rows

    my $disabled_users = $meld->array_of_array_rows(
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        'status',                      # order by clause
    );
    print $disabled_users->[2]->[1];

Returns an array ref of array refs, one for each row returned.

=cut

sub array_of_array_rows {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_execute( 'selectall_arrayref', $sql, \@bind );
}

=head2 array_of_hash_rows

=cut

sub array_of_hash_rows {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_execute( 'selectall_arrayref', $sql, \@bind, { Slice=>{} } );
}

=head2 hash_of_hash_rows

=cut

sub hash_of_hash_rows {
    my ($self, $key, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->run(sub{
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

    my ($count) = $self->array_row(
        $table,
        'COUNT(*)',
        $where,
        @args,
    )->[0];

    return $count;
}

=head2 column

=cut

sub column {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_execute( 'selectcol_arrayref', $sql, \@bind );
}

=head2 select_sth

    my $users_sth;
    foreach my $status (0, 1) {
        $users_sth ||= $meld->select_sth(
            'users',
            ['user_name', 'user_id'],
            {status => $status},
        );

        $users_sth->execute(
            $meld->bind_values( {status => $status} ),
        );
    }

=cut

sub select_sth {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_prepare( $sql );
}

=head2 insert_sth

=cut

sub insert_sth {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->insert( @args );
    return $self->_dbi_prepare( $sql );
}

=head2 update_sth

=cut

sub update_sth {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->update( @args );
    return $self->_dbi_prepare( $sql );
}

=head2 delete_sth

=cut

sub delete_sth {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->delete( @args );
    return $self->_dbi_prepare( $sql );
}

=head2 bind_values

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

