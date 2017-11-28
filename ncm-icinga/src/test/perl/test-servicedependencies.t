#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = [ { foo => 1,
	  } ];

my $rs = $comp->print_servicedependencies();

ok(!defined($rs), "Nothing is done if there are no service dependencies");

$rs = $comp->print_servicedependencies($t);
my $fh = get_file(NCM::Component::icinga::ICINGA_FILES->{servicedependencies});

like($fh, qr(^\s*foo\s+1$)m, "Contents properly written");
