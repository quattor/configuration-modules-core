#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 4;

use myIcinga;

my $comp = NCM::Component::icinga->new('icinga');

my $t = [ { foo => 1,
	  } ];

my $rs = $comp->print_servicedependencies();

ok(!defined($rs), "Nothing is done if there are no service dependencies");


$rs = $comp->print_servicedependencies($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename},
   NCM::Component::icinga::ICINGA_FILES->{servicedependencies},
    "Correct file was opened");
like("$rs", qr(^\s*foo\s+1$)m, "Contents properly written");

$rs->close();
