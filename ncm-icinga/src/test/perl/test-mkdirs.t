#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::icinga;
use File::Path qw(rmtree);

use constant DIR => "target/test/icinga/dirs";


my $cmp = NCM::Component::icinga->new('icinga');

my $t = {
	 check_result_path => DIR,
	};



$cmp->{ERROR} = 0;

$cmp->make_dirs($t);

ok(-d $t->{check_result_path}, "Directory created");
# We might have failed in setting ownership
ok($cmp->{ERROR} <= 1, "No realistic errors when creating the directory");

$cmp->make_dirs({});
ok($cmp->{ERROR} > 1, "Errors reported when creating the directories");
done_testing();
