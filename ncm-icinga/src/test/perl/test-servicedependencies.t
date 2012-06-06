#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Test::More tests => 4;
use File::Find;

use CAF::Application;
our $this_app = new CAF::Application ('a', @ARGV);
use Exporter;
our @EXPORT = ($this_app);

use NCM::Component::icinga;
use CAF::Object;
$CAF::Object::NoAction = 1;

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
