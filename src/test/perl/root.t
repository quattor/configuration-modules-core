#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(root/basic);
use NCM::Component::accounts;

set_file_contents("/etc/passwd",
		  "root:x:0:0:root:home for root:shell for root\n");
set_file_contents("/etc/shadow",
		  "root:a very difficult root password:12345:0:1234567:1:::\n");

my $cmp = NCM::Component::accounts->new('accounts');

my $cfg = get_config_for_profile("root/basic");
my $t = $cfg->getElement("/software/components/accounts")->getTree();

ok(1);

done_testing();
