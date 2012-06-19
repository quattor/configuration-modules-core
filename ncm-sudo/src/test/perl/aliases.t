#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(profile_test0aliases
		     profile_test1aliases_cmderr);
use NCM::Component::sudo;

my $cmp = NCM::Component::sudo->new('sudo');

my $cfg = get_config_for_profile('profile_test0aliases');

my $a = $cmp->generate_aliases($cfg);

foreach my $i (NCM::Component::sudo::USER_ALIASES,
	       NCM::Component::sudo::HOST_ALIASES,
	       NCM::Component::sudo::RUNAS_ALIASES,
	       NCM::Component::sudo::CMD_ALIASES) {
    ok(!@{$a->{$i}}, "$i not defined on empty set");
}

done_testing();
