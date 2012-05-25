#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(groups/consistent groups/inconsistent
		     users/consistent users/inconsistent
		     users/allbroken);
use NCM::Component::accounts;

=pod

=head1 DESCRIPTION

Tests for finding the consistency of a system

=head1 TESTS

For finding whether the system would end in a consistent state, we
need to verify:

=head2 C<groups_are_consistent>

Groups are consistent if all their GIDs are unique.

=cut

my $cmp = NCM::Component::accounts->new('accounts');

my $cfg = get_config_for_profile('groups/consistent');


my $g = $cfg->getElement("/software/components/accounts/groups")->getTree();

ok($cmp->groups_are_consistent($g), "Consistent groups are diagnosed as such");

$cfg = get_config_for_profile('groups/inconsistent');
$g = $cfg->getElement("/software/components/accounts/groups")->getTree();

ok(!$cmp->groups_are_consistent($g), "Inconsistent groups are diagnosed as such");

=pod

=head2 C<accounts_are_consistent>

Accounts are consistent if all their UIDs are unique

=cut

$cfg = get_config_for_profile('users/consistent');
my $t = $cfg->getElement("/software/components/accounts")->getTree();
ok($cmp->accounts_are_consistent($t->{users}, $t->{groups}),
   "Accounts with different UIDs and existing groups are deemed consistent");

$cfg = get_config_for_profile('users/inconsistent');
$t = $cfg->getElement("/software/components/accounts")->getTree();
ok(!$cmp->accounts_are_consistent($t->{users}, $t->{groups}),
   "Accounts with duplicated UIDs are not consistent and rejected");

=pod

=head2 C<is_consistent>

Ensure that all GIDs and UIDs are, indeed, unique

=cut

$t->{passwd} = $t->{users};

ok(!$cmp->is_consistent($t), "Inconsistent system state is prevented");

$cfg = get_config_for_profile('users/allbroken');
$t = $cfg->getElement("/software/components/accounts")->getTree();
$t->{passwd} = $t->{users};

ok(!$cmp->is_consistent($t),
   "Broken profile with everything broken is detected and prevented");
$t->{passwd}->{foo}->{uid} = 42;
ok(!$cmp->is_consistent($t),
   "Broken profile with broken groups but valid users is detected and prevented");

# This fixes the system, and must be accepted.
$t->{groups}->{foo}->{gid} = 42;
ok($cmp->is_consistent($t), "A valid, fixed system is accepted");

done_testing();
