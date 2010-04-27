package DBIx::Meld::Traits::Connector;
BEGIN {
  $DBIx::Meld::Traits::Connector::VERSION = '0.08';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::Connector - Melds DBIx::Connector with DBIx::Meld.

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
    )],
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    # If the first argument looks like a DSN then assume that we're
    # being called in DBIx::Connector style.
    if (@_ and $_[0]=~m{:}) {
        return $class->$orig(
            connector => [ @_ ],
        );
    }

    return $class->$orig(@_);
};

=head1 METHODS

=head2 dbh

=head2 run

=head2 txn

=head2 svp

=cut

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

