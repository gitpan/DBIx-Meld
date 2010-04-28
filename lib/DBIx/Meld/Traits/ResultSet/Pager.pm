package DBIx::Meld::Traits::ResultSet::Pager;
BEGIN {
  $DBIx::Meld::Traits::ResultSet::Pager::VERSION = '0.09';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::ResultSet::Pager - Provide data paging to result sets.

=cut

use Data::Page;
use Carp qw( croak );

=head1 ATTRIBUTES

=head2 pager

    my $rs = $meld->resultset('users')->search({}, {page=>2, rows=>50});
    my $pager = $rs->pager(); # a pre-populated Data::Page object

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

    croak 'pager() can only be called on pageing result sets' if !$self->clauses->{page};

    my $pager = Data::Page->new();
    $pager->total_entries( $self->search({}, {page=>0})->count() );
    $pager->entries_per_page( $self->clauses->{rows} || 10 );
    $pager->current_page( $self->clauses->{page} );

    return $pager;
}

sub _prep_limit {
    my ($self) = @_;
    return if !$self->clauses->{page};

    $self->clauses->{limit} = $self->pager->entries_per_page();
    $self->clauses->{offset} = $self->pager->skipped();

    return;
}

before 'array_of_array_rows' => \&_prep_limit;
before 'array_of_hash_rows' => \&_prep_limit;
before 'hash_of_hash_rows' => \&_prep_limit;
before 'column' => \&_prep_limit;
before 'select_sth' => \&_prep_limit;

around 'count' => sub{
    my $orig = shift;
    my $self = shift;

    return $self->pager->entries_on_this_page() if $self->clauses->{page};
    return $self->$orig( @_ );
};

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

