#!/usr/bin/perl
use strict;
use warnings;

my $class_traits = {
    'Meld' => [qw(
        Connector
        Abstract
        ResultSet
        DateTimeFormat
    )],
    'Meld/ResultSet' => [qw(
        ResultSet/Meld
        ResultSet/Abstract
        ResultSet/Pager
    )],
};

foreach my $class (keys %$class_traits) {
    my $synopsis_pod = '';
    foreach my $trait (@{ $class_traits->{$class} }) {
        my $fn = "lib/DBIx/Meld/Traits/$trait.pm";
        open(my $fh, '<', $fn);

        my $looking = 0;
        my $has_pod = 0;
        my $need_break = 0;
        while (my $line = <$fh>) {
            if (!$looking and $line =~ m{^=head2}) {
                $looking = 1;
                next;
            }
            next if !$looking;
            if ($line =~ m{^=cut}) {
                $looking = 0;
                next;
            }
            if ($line =~ m{^ +}) {
                $synopsis_pod .= "    \n" if $need_break;
                $need_break = 0;
                $synopsis_pod .= $line;
                $has_pod = 1;
                next;
            }
            $need_break = 1 if $has_pod;
        }
        $synopsis_pod .= "    \n";
    }

    $synopsis_pod =~ s{^(    \n)+}{}s;
    $synopsis_pod =~ s{(    \n)+$}{}s;

    my $filename = "lib/DBIx/$class.pm";

    my $content = read_file( $filename );
    $content =~ s{(=head1 SYNOPSIS).+?(=(?:head1|cut))}{$1\n\n$synopsis_pod\n$2}s;
    write_file( "$filename.new", $content );

    my $diff = `diff $filename $filename.new`;
    if ($diff !~ m{\S}s) {
        print "No differences to $filename.\n\n";
        unlink "$filename.new";
        next;
    }

    print $diff;
    print "\nCopy changes to $filename? ";
    my $ok = <STDIN>;
    print "\n\n";
    next if $ok !~ m{y}is;

    `mv $filename.new $filename`;
}

sub read_file {
    my ($fn) = @_;
    open(my $fh, '<', $fn);
    my $content = '';
    while (<$fh>) { $content.=$_; }
    return $content;
}

sub write_file {
    my ($fn, $content) = @_;
    open(my $fh, '>', $fn);
    print $fh $content;
}

__END__

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
