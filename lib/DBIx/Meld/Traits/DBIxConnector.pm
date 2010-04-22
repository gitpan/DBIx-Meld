package DBIx::Meld::Traits::DBIxConnector;
BEGIN {
  $DBIx::Meld::Traits::DBIxConnector::VERSION = '0.01';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::DBIxConnector - Melds DBIx::Connector with DBIx::Meld.

=head1 DESCRIPTION

This trait provides a connector attribute (which must be a DBIx::Connector object)
and proxy methods for each DBIx::Connector method so that the methods may be
called directly on the DBIx::Meld object.

=cut

use DBIx::Connector;

=head1 TYPES

=head2 DBIxConnector

This L<MooseX::Types> type requires that the value be a L<DBIx::Connector>
object.  If the value is an array ref then it will be coerced in to a
DBIx::Connector object by passing it as an array to DBIx::Connector->new().

=cut

use MooseX::Types -declare => [qw(
    DBIxConnector
)];

use MooseX::Types::Moose qw( ArrayRef );

class_type DBIxConnector, { class => 'DBIx::Connector' };
coerce DBIxConnector, from ArrayRef, via { DBIx::Connector->new( @$_ ) };

=head1 ATTRIBUTES

=head2 connector

This is the connector object.  It is required and is of type DBIxConnector.

=cut

has 'connector' => (
    is => 'ro',
    isa => DBIxConnector,
    coerce => 1,
    required => 1,
    handles => [qw(
        dbh
        run
        txn
        svp
        with
        connected
        in_txn
        disconnect
    )],
);

=head1 METHODS

=head2 dbh

=head2 run

=head2 txn

=head2 svp

=head2 with

=head2 connected

=head2 in_txn

=head2 disconnect

=cut

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

