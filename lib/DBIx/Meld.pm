package DBIx::Meld;
BEGIN {
  $DBIx::Meld::VERSION = '0.02';
}
use Moose;
use namespace::autoclean;

=head1 NAME

DBIx::Meld - An ORMish amalgamation.

=head1 SYNOPSIS

    use DBIx::Meld;
    
    my $meld = DBIx::Meld->new( $dsn, $user, $pass );
    $meld->insert( 'users', {user_name => 'smith023'} );
    
    my $rows = $meld->array_of_hash_rows( 'users', ['user_name', 'email'], {status => 1} );
    foreach my $row (@$rows) {
        print "$row->{user_name}: $row->{email}\n";
    }
    
    # or, in a more ORMish fashion:
    my $users = $meld->resultset('users');
    $users->insert({user_name => 'smith023'});
    
    my $rows = $users->search({ status => 1 })->array_of_hash_rows(['user_name', 'email']);

=head1 DESCRIPTION

This module combines the features of L<DBIx::Connector>, L<SQL::Abstract>,
and the various DateTime::Format modules, with some of the design concepts
of L<DBIx::Class>.

=head1 WHY

L<DBIx::Class> is a really great tool.  But, it doesn't fit some situations
as it is too heavyweight in other situations.  In these situations, where you
find yourself having to write raw DBI calls, you are suddenly left without
all of the great features that DBIx::Class provides, such as:

=over

=item Robust connection and transation handling.

=item Greatly reduced need to write raw SQL.

=item Database independent date and time handling.

=item Ability to progressively construct queries using resultsets.

=back

So, the intent of this module is to fill this gap.  With this module you
are still dealing with low-level DBI calls, but you get many of the great
benefits that DBIx::Class provides.

=head1 CONSTRUCTOR

There are several ways to create a new DBIx::Meld object.  The most
common way is to call it just like DBIx::Connector:

    my $meld = DBIx::Meld->new( $dsn, $user, $pass, $attrs ); # $attrs is optional

Or you can do it using name/value pairs:

    my $meld = DBIx::Meld->new( connector => [$dsn, $user, $pass] );

The connector attribute may also be an already blessed object:

    my $connector = DBIx::Connector->new( $dsn, $user, $pass );
    my $meld = DBIx::Meld->new( connector => $connector );

=cut

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

=head1 TRAITS

=head2 DBIxConnector

    $meld->txn(sub{ ... });
    
    # This does the same thing:
    $meld->connector->txn(sub{ ... });

This traite provides all of L<DBIx::Connector>'s methods as methods on DBIx::Meld.
Ready more at L<DBIx::Meld::Traits::DBIxConnector>.

=cut

with 'DBIx::Meld::Traits::DBIxConnector';

=head2 SQLAbstract

    $meld->insert('users', {user_name => 'smith023'});

This trait provides access to most of L<SQL::Abstract>'s methods as methods
on DBIx::Meld.  Ready more at L<DBIx::Meld::Traits::SQLAbstract>.

=cut

with 'DBIx::Meld::Traits::SQLAbstract';

=head2 DateTimeFormat

    $meld->format_datetime( DateTime->now() );

This trait provides access to the appropriate DateTime::Format module and
provides helper methods on DBIx::Meld.  Read more at L<DBIx::Meld::Traits::DateTimeFormat>.

=cut

with 'DBIx::Meld::Traits::DateTimeFormat';

=head2 ResultSet

    my $user = $meld->resultset('users');

This trait provides the resultset() method which, when given a table
name, returns an L<DBIx::Meld::ResultSet> object.  Read me at
L<DBIx::Meld::Traits::ResultSet>.

=cut

with 'DBIx::Meld::Traits::ResultSet';

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 TODO

=over

=item Support GROUP BY, HAVING, and LIMIT (and Data::Page?) clauses when selecting data.

=item Integrate DBIC's well-tested auto-generated ID retrieval code.  This can be tricky
since each DB does it in a different way (/looks at Oracle).  Then, insert() can
return that ID.

=item Support pluggable traits so that other CPAN authors can release distros that easly
plug in and add functionality.

=back

=head1 AUTHOR

Aran Clary Deltac <bluefeet@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

