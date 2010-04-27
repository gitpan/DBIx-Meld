package DBIx::Meld::Traits::ResultSet::Meld;
BEGIN {
  $DBIx::Meld::Traits::ResultSet::Meld::VERSION = '0.08';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::ResultSet::Meld - Provides a meld object to result sets.

=head1 ATTRIBUTES

=head2 meld

The L<DBIx::Meld> object that this result set is using.  This attribute provides a
proxy method to connector so that you can do:

=cut

has 'meld' => (
    is       => 'ro',
    isa      => 'DBIx::Meld',
    required => 1,
    handles => [qw(
        connector
        abstract
    )],
);

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

