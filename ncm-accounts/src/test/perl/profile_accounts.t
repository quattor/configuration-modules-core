#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simpleaccounts poolaccounts);
use NCM::Component::accounts;

=pod

=head1 DESCRIPTION

Test how the profile structure is expanded in the presence of pool
accounts.

=head1 TESTS

=head2 Simple case

One account, no pools. The name must be added to the account.

=cut

my $cmp = NCM::Component::accounts->new("accounts");
my $cfg = get_config_for_profile("simpleaccounts");
my $t = $cfg->getElement("/software/components/accounts")->getTree();
my $a = $cmp->compute_desired_accounts($t->{users});
is(scalar(keys(%$a)), 1,
   "No expansion on non-pool accounts in simple profile");
is($a->{test}->{name}, "test", "Account name added to the structure");

=pod

=head2 Pool case

One pool account with three members, one non-pool account.

=cut

$cfg = get_config_for_profile("poolaccounts");
$t = $cfg->getElement("/software/components/accounts")->getTree();
$a = $cmp->compute_desired_accounts($t->{users});
my $p = $t->{users}->{pool};
is(scalar(grep($_ =~ m{pool\d+}, keys(%$a))),
   $p->{poolSize},
   "Correct amount of pool accounts was created");
for my $i ($p->{poolStart}..$p->{poolStart}+$p->{poolSize}-1) {
    my $an = sprintf("%s%0$p->{poolDigits}d", "pool", $i);
    ok(exists($a->{$an}), "Pool account was correctly created");
    is($a->{$an}->{homeDir}, "/home/$an",
       "Pool account has the correct home");
    is($a->{$an}->{name}, $an, "Pool account $an has the correct name");
}

done_testing();
