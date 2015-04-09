#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(profile_0opts profile_all_options profile_empty);
use NCM::Component::sudo;

=pod

=head1 DESCRIPTION

Test the generation of defaults lines for /etc/sudoers.

=cut

my $cmp = NCM::Component::sudo->new('sudo');

my $cfg = get_config_for_profile('profile_0opts');

my $o = $cmp->generate_general_options($cfg);

is(scalar(@$o), 0, "No options defined on empty list");

$cfg = get_config_for_profile('profile_all_options');

$o = $cmp->generate_general_options($cfg);

is(scalar(@$o), 8, "All options were processed");
is($o->[0], ">r", "run_as defaults correctly processed");
is($o->[1], '@h', "host defaults correctly processed");
is($o->[2], ':u', "user defaults correctly processed");
is($o->[3], '!c', 'command defaults correctly processed');
is($o->[4], "", "No modifier leads to empty line heading");
like($o->[5], qr{^\s+listpw\s*=\s*hello\s*$}, "String defaults correctly processed");
like($o->[6], qr{^\s+loglinelen\s*=\s*5\s*$}, "Integer defaults correctly processed");
like($o->[7], qr{^\s+!insults,requiretty,editor=vim\s*$}, "List with boolean and string defaults correctly processed");

$cfg = get_config_for_profile('profile_empty');
$o = $cmp->generate_general_options($cfg);
is($o, undef, "Non-existing defaults lead to undef object");

done_testing();
