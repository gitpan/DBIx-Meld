package DBIx::Meld::ResultSet;
BEGIN {
  $DBIx::Meld::ResultSet::VERSION = '0.07';
}
use Moose;
use namespace::autoclean;

=head1 NAME

DBIx::Meld::ResultSet - An ORMish representation of a SQL query.

=head1 SYNOPSIS

    my $old_rs = $meld->resultset('users')->search({ status => 0 });
    my $new_rs = $old_rs->search({ age > 18 });
    print 'Disabled adults: ' . $new_rs->count() . "\n";
    
    $rs->insert({ user_name => 'joe_bob' });
    
    $rs->update({ email => 'joe@example.com' });
    
    $rs->delete();
    
    my $row = $rs->array_row(['user_name', 'email']);
    print $row->[0]; # user_name
    print $row->[1]; # email
    
    my $row = $rs->hash_row(); # defaults to '*' (all columns)
    print $row->{user_name};
    
    my $rows = $rs->array_of_array_rows(['user_name', 'user_id']);
    foreach my $row (@$rows) {
        print $row->[0] . "\n";
    }
    
    my $rows = $rs->array_of_hash_rows(['user_name', 'user_id']);
    foreach my $row (@$rows) {
        print $row->{user_name} . "\n";
    }
    
    my $rows = $rs->hash_of_hash_rows('user_id', ['user_id', 'user_name', 'email']);
    foreach my $user_id (keys %$rows) {
        print "$user_id: $rows->{$user_id}->{email}\n";
    }
    
    print $rs->count() . "rows!\n";
    
    my $user_names = $rs->column('user_name');
    foreach my $user_name (@$user_names) { ... }
    
    my ($sth, @bind) = $rs->select_sth(['user_id', 'user_name']);
    
    my $insert_sth;
    foreach my $user_name (qw( jsmith bdoe )) {
        my $fields = { user_name=>$user_name };
    
        $insert_sth ||= $rs->insert_sth( $fields );
    
        $insert_sth->execute( $rs->bind_values( $fields ) );
    }

    my $rs = $meld->resultset('users')->search({}, {page=>2, rows=>50});
    my $pager = $rs->pager(); # a pre-populated Data::Page object
    
    print $rs->total_entries();
    
    print $rs->pager->total_entries();

=head1 DESCRIPTION

This class is a very lightweight wrapper around L<DBIx::Meld>.  All it does is
remember the table name for all of the L<SQL::Abstract> queries, like update(),
and provides a way to progressively build a SQL query, much like L<DBIx::Class::ResultSet>.

=head1 TRAITS

This module's features are all provided by traits.  If you need details
about this module's API, then you'll want to read up on the relevant trait.

=head2 Meld

Provides the meld() method for other traits to use.
Ready more at L<DBIx::Meld::Traits::ResultSet::Meld>.

=cut

with 'DBIx::Meld::Traits::ResultSet::Meld';

=head2 Abstract

Additional simplifications to the various insert/update/delete/select
calls as well as the ability to search() on a resultset.
Ready more at L<DBIx::Meld::Traits::ResultSet::Abstract>.

=cut

with 'DBIx::Meld::Traits::ResultSet::Abstract';

=head2 Pager

Provides the ability to page a resultset.
Ready more at L<DBIx::Meld::Traits::ResultSet::Pager>.

=cut

with 'DBIx::Meld::Traits::ResultSet::Pager';

use Carp qw( croak );

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

