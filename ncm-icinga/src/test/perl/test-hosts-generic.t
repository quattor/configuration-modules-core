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

my $t = { ahost => {
		    check_command => [qw(foo bar baz)],
		    event_handler => [qw(hello world)],
		    a => 1,
		    b => 2,
		    c => [5..7]
		   }
	};

my $rs = $comp->print_hosts_generic(undef);
ok(!defined($rs), "If the tree is empty it does nothing");

$rs = $comp->print_hosts_generic($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");

is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{hosts_generic},
   "Correct file was opened");

like("$rs", qr(^\s*event_handler\s+hello!world$)m,
     "Event handler properly registered");
like("$rs", qr(^\s*check_command\s+foo!bar!baz$)m,
     "Check command properly registered");
like("$rs", qr(^\s*a\s+1$)m,
     "Random scalar key properly defined");
like("$rs", qr(^\s*c\s+5,6,7$)m,
     "Random array key properly defined");
