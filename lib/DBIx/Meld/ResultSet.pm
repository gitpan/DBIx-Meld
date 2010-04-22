package DBIx::Meld::ResultSet;
BEGIN {
  $DBIx::Meld::ResultSet::VERSION = '0.03';
}
use Moose;
use namespace::autoclean;

=head1 NAME

DBIx::Meld::ResultSet - An ORMish representation of a SQL query.

=head1 SYNOPSIS

    my $rs = $meld->resultset('users');
    my $disabled_users = $rs->search({ status => 0 });
    print 'Number of disabled users: ' . $disabled_users->count() . "\n";

=head1 DESCRIPTION

This class is a very lightweight wrapper around L<DBIx::Meld>.  All it does is
remember the table name for all of the L<SQL::Abstract> queries, like update(),
and provides a way to progressively build a SQL query, much like L<DBIx::Class::ResultSet>.

=cut

has 'meld' => (
    is       => 'ro',
    isa      => 'DBIx::Meld',
    required => 1,
    handles => [qw(
        connector
    )],
);

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'where' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

with 'DBIx::Meld::Traits::SQLAbstract';

=head1 METHODS

=head2 search

    my $old_rs = $meld->resultset('users')->search({ status => 0 });
    my $new_rs = $old_rs->search({ age > 18 });
    print 'Disabled adults: ' . $new_rs->count() . "\n";

Returns a new resultset object that overlays the passed in where clause
on top of the old where clause, creating a new resultset.  The original
resultset's where clause is left unmodified.

=cut

sub search {
    my ($self, $where) = @_;

    my $new_where = { %{ $self->where() } };
    map { $new_where->{$_} = $where->{$_} } keys %$where;

    return DBIx::Meld::ResultSet->new(
        meld  => $self->meld(),
        table => $self->table().
        where => $new_where,
    );
}

=head2 insert

    my $users = $meld->resultset('users');
    $users->insert({ user_name => 'joe_bob' });

=cut

around 'insert' => sub{
    my ($orig, $self, @args) = @_;
    return $self->$orig->insert( $self->table(), @args );
};

=head2 update

    my $users = $meld->resultset('users');
    $users->search({ user_name => 'joe_bob' })->update({ email => 'joe@example.com' });

=cut

around 'update' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 delete

    $meld->resultset('users')->search({ user_id => 12 })->delete();

=cut

around 'delete' => sub{
    my ($orig, $self, @args) = @_;
    return $self->$orig( $self->table(), $self->where(), @args );
};

=head2 array_row

    my $row = $users->search({ user_id => 12 })->array_row(['user_name', 'email']);
    print $row->[0]; # user_name
    print $row->[1]; # email

=cut

around 'array_row' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 hash_row

    my $row = $users->search({ user_id => 12 })->hash_row('*');
    print $row->{user_name};

=cut

around 'hash_row' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 array_of_array_rows

    my $rows = $users->search({ status => 1 })->array_of_array_rows(['user_name']);
    foreach my $row (@$rows) {
        print $row->[0] . "\n";
    }

=cut

around 'array_of_array_rows' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 array_of_hash_rows

=cut

around 'array_of_hash_rows' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 hash_of_hash_rows

=cut

around 'hash_of_hash_rows' => sub{
    my ($orig, $self, $key, $fields, @args) = @_;
    return $self->$orig( $key, $self->table(), $fields, $self->where(), @args );
};

=head2 count

=cut

around 'count' => sub{
    my ($orig, $self, @args) = @_;
    return $self->$orig( $self->table(), $self->where(), @args );
};

=head2 column

=cut

around 'column' => sub{
    my ($orig, $self, $column, @args) = @_;
    return $self->$orig( $self->table(), $column, $self->where(), @args );
};

=head2 select_sth

=cut

around 'select_sth' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 insert_sth

=cut

around 'insert_sth' => sub{
    my ($orig, $self, @args) = @_;
    return $self->$orig( $self->table(), @args );
};

=head2 update_sth

=cut

around 'update_sth' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), @args );
};

=head2 delete_sth

=cut

around 'delete_sth' => sub{
    my ($orig, $self, $fields, @args) = @_;
    return $self->$orig( $self->table(), $self->where(), @args );
};

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

