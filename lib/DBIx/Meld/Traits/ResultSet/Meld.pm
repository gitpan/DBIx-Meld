package DBIx::Meld::Traits::ResultSet::Meld;
BEGIN {
  $DBIx::Meld::Traits::ResultSet::Meld::VERSION = '0.06';
}
use Moose::Role;

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

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

