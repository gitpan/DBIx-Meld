#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require DBD::SQLite };
    plan skip_all => 'this test requires DBD::SQLite' if $@;
}

use Test::Exception;
use DBIx::Meld;

dies_ok { DBIx::Meld->new() } 'new without args dies';

my @args = ('dbi:SQLite:dbname=t/test.db', '', '');

my %test_cases = (
    connector => \@args,
    coerced   => [ connector => \@args ],
    verbose   => [ connector => DBIx::Connector->new( @args ) ],
);

foreach my $case (keys %test_cases) {
    my $case_args = $test_cases{$case};
    my $meld = DBIx::Meld->new( @$case_args );
    isa_ok( $meld->connector(), 'DBIx::Connector', $case . ' constructor:' );
}

done_testing;
1;
