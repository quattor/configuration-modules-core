#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Test::More tests => 3;
use File::Find;

use CAF::Application;
our $this_app = new CAF::Application ('a', @ARGV);
use Exporter;
our @EXPORT = ($this_app);

BEGIN {

    my $lib;
    File::Find::find(sub {
			 if ($_ eq 'icinga.pm' &&
			     $File::Find::dir ne "$Bin/..") {
			     $lib = $File::Find::name
			 }
		     },
		     "$Bin/..");
    $lib =~ m{(.*)/NCM/Component/icinga.pm} or die "Not found! $lib";
    unshift(@INC, $1);
}

use NCM::Component::icinga;
use CAF::Object;
$CAF::Object::NoAction = 1;

my $comp = NCM::Component::icinga->new('icinga');

my $t = { foo => 'bar' };

my $rs = $comp->print_ido2db_config($t);
isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{ido2db},
   "Correct file was opened");
chomp($rs);
is($rs, "foo=bar", "Contents properly written");

