#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(profile_test0aliases
		     profile_all_aliases
		     profile_test1aliases);
use NCM::Component::sudo;

=pod

=head1 DESCRIPTION

Test how aliases are generated. We need to test B<user>, B<run_as>,
B<command> and B<host> aliases.

=cut

my $cmp = NCM::Component::sudo->new('sudo');

my $cfg = get_config_for_profile('profile_test0aliases');

my $a = $cmp->generate_aliases($cfg);

foreach my $i (NCM::Component::sudo::USER_ALIASES,
	       NCM::Component::sudo::HOST_ALIASES,
	       NCM::Component::sudo::RUNAS_ALIASES,
	       NCM::Component::sudo::CMD_ALIASES) {
    ok(!@{$a->{$i}}, "$i not defined on empty set");
}

$cfg = get_config_for_profile('profile_test1aliases');

$a = $cmp->generate_aliases($cfg);

is(scalar(@{$a->{NCM::Component::sudo::USER_ALIASES()}}), 1,
   "Basic user alias added");
like($a->{NCM::Component::sudo::USER_ALIASES()}->[0],
     qr{FOO\s+=\s+bar}, "User alias has the correct form");

$cfg = get_config_for_profile('profile_all_aliases');
$a = $cmp->generate_aliases($cfg);

foreach my $i (NCM::Component::sudo::USER_ALIASES,
	       NCM::Component::sudo::HOST_ALIASES,
	       NCM::Component::sudo::RUNAS_ALIASES,
	       NCM::Component::sudo::CMD_ALIASES) {
    ok(@{$a->{$i}}, "$i not defined on empty set");
}

like($a->{NCM::Component::sudo::HOST_ALIASES()}->[0],
     qr{HOST\s+=\s+\w+\s*,\w+}, "List of alias members correctly generated");

done_testing();
