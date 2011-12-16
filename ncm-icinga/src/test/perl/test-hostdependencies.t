#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Test::More tests => 6;
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

my $t = { ahost => { foo => 1,
		     bar => [3,4],
		   }
	};

my $rs = $comp->print_hostdependencies();

ok(!defined($rs), "Nothing is done if there are no host dependencies");


$rs = $comp->print_hostdependencies($t);

isa_ok($rs, 'CAF::FileWriter', "Returned object is a FileWriter");
is(*$rs->{filename}, NCM::Component::icinga::ICINGA_FILES->{hostdependencies},
   "Correct file was opened");
like("$rs", qr(^\s*foo\s+1$)m, "Scalar contents properly written");
like("$rs", qr(^\s*bar\s+3,4$)m, "List contents properly written");
like("$rs", qr(^\s*host_name\s+ahost$)m, "Host name properly recorded");
