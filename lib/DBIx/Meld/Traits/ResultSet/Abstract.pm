package DBIx::Meld::Traits::ResultSet::Abstract;
BEGIN {
  $DBIx::Meld::Traits::ResultSet::Abstract::VERSION = '0.08';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::ResultSet::Abstract - Provides SQL::Abstract methods to result sets.

=cut

use Clone qw( clone );
use List::MoreUtils qw( uniq );

=head1 ATTRIBUTES

=head2 table

The name of the table that this result set will be using for queries.

=cut

has 'table' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

=head2 where

The where clause hash ref to be used when executing queries.

=cut

has 'where' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head2 clauses

Additional clauses, such as order_by, limit, offset, etc.

=cut

has 'clauses' => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub{ {} },
);

=head1 METHODS

=head2 search

    my $old_rs = $meld->resultset('users')->search({ status => 0 });
    my $new_rs = $old_rs->search({ age > 18 });
    print 'Disabled adults: ' . $new_rs->count() . "\n";

Returns a new result set object that overlays the passed in where clause
on top of the old where clause, creating a new result set.  The original
result set's where clause is left unmodified.

=cut

sub search {
    my ($self, $where, $clauses) = @_;

    $where ||= {};
    my $new_where = clone( $self->where() );
    map { $new_where->{$_} = $where->{$_} } keys %$where;

    my $new_clauses = {};
    foreach my $clause (uniq sort (keys %$clauses, keys %{$self->clauses()})) {
        if (exists $clauses->{$clause}) {
            $new_clauses->{$clause} = clone( $clauses->{$clause} );
        }
        else {
            $new_clauses->{$clause} = clone( $self->clauses->{$clause} );
        }
    }

    return DBIx::Meld::ResultSet->new(
        meld    => $self->meld(),
        table   => $self->table(),
        where   => $new_where,
        clauses => $new_clauses,
    );
}

=head2 insert

    $rs->insert({ user_name => 'joe_bob' });

=cut

sub insert {
    my ($self, $fields, $clauses) = @_;
    return $self->meld->insert( $self->table(), $fields, $clauses );
}

=head2 update

    $rs->update({ email => 'joe@example.com' });

=cut

sub update {
    my ($self, $values) = @_;
    return $self->meld->update( $self->table(), $values, $self->where() );
}

=head2 delete

    $rs->delete();

=cut

sub delete {
    my ($self) = @_;
    return $self->meld->delete( $self->table(), $self->where() );
};

=head2 array_row

    my $row = $rs->array_row(['user_name', 'email']);
    print $row->[0]; # user_name
    print $row->[1]; # email

=cut

sub array_row {
    my ($self, $fields) = @_;

    return $self->meld->array_row(
        $self->table(),
        $fields,
        $self->where(),
        $self->clauses(),
    );
}

=head2 hash_row

    my $row = $rs->hash_row(); # defaults to '*' (all columns)
    print $row->{user_name};

=cut

sub hash_row {
    my ($self, $fields) = @_;

    return $self->meld->hash_row(
        $self->table(),
        $fields,
        $self->where(),
        $self->clauses(),
    );
}

=head2 array_of_array_rows

    my $rows = $rs->array_of_array_rows(['user_name', 'user_id']);
    foreach my $row (@$rows) {
        print $row->[0] . "\n";
    }

=cut

sub array_of_array_rows {
    my ($self, $fields) = @_;

    return $self->meld->array_of_array_rows(
        $self->table(),
        $fields,
        $self->where(),
        $self->clauses(),
    );
};

=head2 array_of_hash_rows

    my $rows = $rs->array_of_hash_rows(['user_name', 'user_id']);
    foreach my $row (@$rows) {
        print $row->{user_name} . "\n";
    }

=cut

sub array_of_hash_rows {
    my ($self, $fields) = @_;

    return $self->meld->array_of_hash_rows(
        $self->table(),
        $fields,
        $self->where(),
        $self->clauses(),
    );
}

=head2 hash_of_hash_rows

    my $rows = $rs->hash_of_hash_rows('user_id', ['user_id', 'user_name', 'email']);
    foreach my $user_id (keys %$rows) {
        print "$user_id: $rows->{$user_id}->{email}\n";
    }

=cut

sub hash_of_hash_rows {
    my ($self, $key, $fields) = @_;

    return $self->meld->hash_of_hash_rows(
        $key,
        $self->table(),
        $fields,
        $self->where(),
        $self->clauses(),
    );
}

=head2 count

    print $rs->count() . "rows!\n";

=cut

sub count {
    my ($self) = @_;
    return ( $self->array_row( 'COUNT(*)' ) )->[0];
}

=head2 column

    my $user_names = $rs->column('user_name');
    foreach my $user_name (@$user_names) { ... }

=cut

sub column {
    my ($self, $column) = @_;

    return $self->meld->column(
        $self->table(),
        $column,
        $self->where(),
        $self->clauses(),
    );
}

=head2 select_sth

    my ($sth, @bind) = $rs->select_sth(['user_id', 'user_name']);

=cut

sub select_sth {
    my ($self, $fields) = @_;

    return $self->meld->select_sth(
        $self->table(),
        $fields,
        $self->where(),
        $self->clauses(),
    );
};

=head2 insert_sth

    my $insert_sth;
    foreach my $user_name (qw( jsmith bdoe )) {
        my $fields = { user_name=>$user_name };

        $insert_sth ||= $rs->insert_sth( $fields );

        $insert_sth->execute( $rs->bind_values( $fields ) );
    }

=cut

sub insert_sth {
    my ($self, $values) = @_;
    return $self->meld->insert_sth( $self->table(), $values );
};

=head2 bind_values

See insert_sth(), above.

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

