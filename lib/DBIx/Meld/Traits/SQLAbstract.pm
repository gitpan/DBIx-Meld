package DBIx::Meld::Traits::SQLAbstract;
BEGIN {
  $DBIx::Meld::Traits::SQLAbstract::VERSION = '0.01';
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

sub _dbi_callout {
    my ($self, $dbh_method, $sql, $bind, $dbh_attrs) = @_;

    return $self->run(sub{
        my ($dbh) = @_;
        my $sth = $dbh->prepare_cached( $sql );
        return $dbh->$dbh_method( $sth, $dbh_attrs, @$bind );
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

    $self->run(sub{
        my ($dbh) = @_;
        my ($sql, @bind) = $self->abstract->insert( @args );
        $self->_dbi_callout( 'do', $sql, \@bind );
    });

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

    $self->run(sub{
        my ($dbh) = @_;
        my ($sql, @bind) = $self->abstract->update( @args );
        $self->_dbi_callout( 'do', $sql, \@bind );
    });

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

    $self->run(sub{
        my ($dbh) = @_;
        my ($sql, @bind) = $self->abstract->delete( @args );
        $self->_dbi_callout( 'do', $sql, \@bind );
    });

    return;
}

=head2 row_array

    my $user = $sweeet->selectrow_array(
        'users',                                  # table name
        ['user_id', 'created', 'email', 'phone'], # fields to retrieve
        { user_name => $uname },                  # where clause
    );

=cut

sub row_array {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return [ $self->_dbi_callout( 'selectrow_array', $sql, \@bind ) ];
}

=head2 row_hash

    my $user = $meld->row_hash(
        'users',                    # table name
        ['user_id', 'created'],     # fields to retrieve
        { user_name => 'bob2003' }, # where clause
    );

=cut

sub row_hash {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_callout( 'selectrow_hashref', $sql, \@bind );
}

=head2 array_of_row_arrays

    my $disabled_users = $meld->selectall_arrayref(
        'users',                       # table name
        ['user_id', 'email', 'phone'], # fields to retrieve
        { status => 0 },               # where clause
        'status',                      # order by clause
    );
    print $disabled_users->[2]->[1];

Returns an array ref of array refs, one for each row returned.

=cut

sub array_of_row_arrays {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_callout( 'selectall_arrayref', $sql, \@bind );
}

=head2 array_of_row_hashes

=cut

sub array_of_row_hashes {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_callout( 'selectall_arrayref', $sql, \@bind, { Slice=>{} } );
}

=head2 hash_of_row_hashes

=cut

sub hash_of_row_hashes {
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

    my ($count) = $self->selectrow_array(
        $table,
        'COUNT(*)',
        $where,
        @args,
    );

    return $count;
}

=head2 column

=cut

sub column {
    my ($self, @args) = @_;
    my ($sql, @bind) = $self->abstract->select( @args );
    return $self->_dbi_callout( 'selectcol_arrayref', $sql, \@bind );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

