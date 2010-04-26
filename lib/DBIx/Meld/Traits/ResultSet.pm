package DBIx::Meld::Traits::ResultSet;
BEGIN {
  $DBIx::Meld::Traits::ResultSet::VERSION = '0.06';
}
use Moose::Role;

=head1 NAME

DBIx::Meld::Traits::ResultSet - Provides resultsets to DBIx::Meld.

=cut

use DBIx::Meld::ResultSet;

=head1 METHODS

=head2 resultset

    my $rs = $meld->resultset('users');

Given a table name, this method will return a new L<DBIx::Meld::ResultSet> object.

=cut

sub resultset {
    my ($self, $table) = @_;

    return DBIx::Meld::ResultSet->new(
        meld  => $self,
        table => $table,
    );
}

1;
__END__

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

