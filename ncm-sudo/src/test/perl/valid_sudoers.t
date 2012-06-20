#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
# Don't use Test::Quattor here. We really need to run the visudo
# command to ensure valid configurations get detected.
use NCM::Component::sudo;

use constant INVALID => "123445";
use constant VALID => "root ALL=(ALL) NOPASSWD: ALL\n";

my $cmp = NCM::Component::sudo->new('sudo');

ok($cmp->is_valid_sudoers(VALID), "Valid /etc/sudoers correctly recognized");
ok(!$cmp->is_valid_sudoers(INVALID), "Invalid /etc/sudoers correctly recognized");

done_testing();
