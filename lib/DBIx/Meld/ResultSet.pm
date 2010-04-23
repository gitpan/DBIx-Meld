package DBIx::Meld::ResultSet;
BEGIN {
  $DBIx::Meld::ResultSet::VERSION = '0.05';
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

with 'DBIx::Meld::Traits::SQLAbstract';

use Data::Page;
use Carp qw( croak );
use Clone qw( clone );

=head1 ATTRIBUTES

=head2 meld

The L<DBIx::Meld> object that this resultset is using.  This attribute provides a
proxy method to connector so that you can do:

    $resultset->connector->run(sub{  ... });

Instead of:

    $resultset->meld->connector->run(sub{ ... });

=cut

has 'meld' => (
    is       => 'ro',
    isa      => 'DBIx::Meld',
    required => 1,
    handles => [qw(
        connector
    )],
);

=head2 table

The name of the table that this resultset will be using for queries.

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

=head2 order_by

An order by value just like L<SQL::Abstract> accepts.

=cut

has 'order_by' => (
    is  => 'ro',
    isa => 'Defined',
);

=head2 rows

The number of rows to return or, if pageing, then number of rows per-page.
Note that this does not limit the number of rows updated/deleted.

=cut

has 'rows' => (
    is  => 'ro',
    isa => 'Int',
);

=head2 page

The page number.  If set, then this resultset will become paged
and you will be able to access the pager() attribute.

=cut

has 'page' => (
    is  => 'ro',
    isa => 'Int',
);

=head2 pager

A L<Data::Page> object pre-populated based on page() and rows().  If
page() has not been specified then trying to access page() will throw
a fatal error.

The total_entries and last_page methods are proxied from the pager in
to this class so that you can call:

    print $rs->total_entries();

Instead of:

    print $rs->pager->total_entries();

=cut

has 'pager' => (
    is         => 'ro',
    isa        => 'Data::Page',
    lazy_build => 1,
    handles => [qw(
        total_entries
        last_page
    )],
);
sub _build_pager {
    my ($self) = @_;

    croak 'pager() can only be called on pageing resultsets' if !$self->page();

    my $pager = Data::Page->new();
    $pager->total_entries( $self->search({}, {page=>0})->count() );
    $pager->entries_per_page( $self->rows() || 10 );
    $pager->current_page( $self->page() );

    return $pager;
}

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
    my ($self, $where, $clauses) = @_;

    $where ||= {};
    my $new_where = clone( $self->where() );
    map { $new_where->{$_} = $where->{$_} } keys %$where;

    foreach my $clause (qw( order_by rows page )) {
        next if defined $clauses->{$clause};

        my $value = $self->$clause();
        next if !defined $value;

        $value = clone( $value) if (ref $value);
        $clauses->{$clause} = $value;
    }

    return DBIx::Meld::ResultSet->new(
        meld    => $self->meld(),
        table   => $self->table(),
        where   => $new_where,
        %$clauses,
    );
}

=head2 insert

    my $users = $meld->resultset('users');
    $users->insert({ user_name => 'joe_bob' });

=cut

around 'insert' => sub{
    my ($orig, $self, $values) = @_;
    return $self->$orig( $self->table(), $values );
};

=head2 update

    my $users = $meld->resultset('users');
    $users->search({ user_name => 'joe_bob' })->update({ email => 'joe@example.com' });

=cut

around 'update' => sub{
    my ($orig, $self, $values) = @_;
    return $self->$orig( $self->table(), $values, $self->where() );
};

=head2 delete

    $meld->resultset('users')->search({ user_id => 12 })->delete();

=cut

around 'delete' => sub{
    my ($orig, $self, @args) = @_;
    return $self->$orig( $self->table(), $self->where() );
};

=head2 array_row

    my $row = $users->search({ user_id => 12 })->array_row(['user_name', 'email']);
    print $row->[0]; # user_name
    print $row->[1]; # email

=cut

sub _clause_args {
    my ($self) = @_;
    my @args;

    push @args, $self->order_by() || '';
    return @args if !$self->page();

    push @args, $self->pager->entries_per_page();
    push @args, $self->pager->skipped();
    return @args;
}

around 'array_row' => sub{
    my ($orig, $self, $fields) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), $self->_clause_args() );
};

=head2 hash_row

    my $row = $users->search({ user_id => 12 })->hash_row('*');
    print $row->{user_name};

=cut

around 'hash_row' => sub{
    my ($orig, $self, $fields) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), $self->_clause_args() );
};

=head2 array_of_array_rows

    my $rows = $users->search({ status => 1 })->array_of_array_rows(['user_name']);
    foreach my $row (@$rows) {
        print $row->[0] . "\n";
    }

=cut

around 'array_of_array_rows' => sub{
    my ($orig, $self, $fields) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), $self->_clause_args() );
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
    my ($orig, $self, $key, $fields) = @_;
    return $self->$orig( $key, $self->table(), $fields, $self->where(), $self->_clause_args() );
};

=head2 count

=cut

around 'count' => sub{
    my ($orig, $self) = @_;
    return $self->pager->entries_on_this_page() if $self->page();
    return $self->$orig( $self->table(), $self->where(), $self->_clause_args() );
};

=head2 column

=cut

around 'column' => sub{
    my ($orig, $self, $column) = @_;
    return $self->$orig( $self->table(), $column, $self->where(), $self->_clause_args() );
};

=head2 select_sth

=cut

around 'select_sth' => sub{
    my ($orig, $self, $fields) = @_;
    return $self->$orig( $self->table(), $fields, $self->where(), $self->_clause_args() );
};

=head2 insert_sth

=cut

around 'insert_sth' => sub{
    my ($orig, $self, @args) = @_;
    return $self->$orig( $self->table(), @args );
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

