#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Test::More tests => 7;
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

my $t = { aservice => [{
			check_command => [1, 2],
			event_handler => [3, 4],
			foo => [5,6],
			event_handler_enabled => 1,
		       }]
	};

my $rs = $comp->print_services($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{services},
   "Correct file was opened");
like("$rs", qr(^\s*service_description\taservice$)m,
     "Service description properly registered");
like("$rs", qr(^\s*check_command\s+1!2$)m,
     "Check command properly registered");
like("$rs", qr(^\s*event_handler\s+3!4$)m,
     "Event handler properly registered");
like("$rs", qr(^\s*event_handler_enabled\s+1$)m,
     "Event handler is enabled");
like("$rs", qr(^\s*foo\s+5,6$)m,
     "Random array field is properly displayed");


