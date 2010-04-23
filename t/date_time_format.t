#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require DateTime };
    plan skip_all => 'this test requires DateTime' if $@;

    eval { require DateTime::Format::SQLite };
    plan skip_all => 'this test requires DateTime::Format::SQLite' if $@;

    eval { require DBD::SQLite };
    plan skip_all => 'this test requires DBD::SQLite' if $@;
}

use DBIx::Meld;
use DateTime;

my $meld = DBIx::Meld->new( 'dbi:SQLite:dbname=t/test.db', '', '' );

is(
    $meld->format_date(DateTime->new(year=>2005, month=>9, day=>23)),
    '2005-09-23',
    'format_date produced expected result',
);

done_testing;
1;
