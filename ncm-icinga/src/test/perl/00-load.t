#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin";
use Test::More tests => 1;
use File::Find;

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

use_ok("NCM::Component::icinga");

