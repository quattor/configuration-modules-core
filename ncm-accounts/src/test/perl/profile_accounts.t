#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simpleaccounts poolaccounts requiredgroupmembers);
use NCM::Component::accounts;
use Readonly;
use CAF::Object;

$CAF::Object::NoAction = 1;


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

=pod

=head2 Group with required members

A group with a required member not defined in the configuration

=cut

Readonly my $LOGIN_DEFS => '/etc/login.defs';
Readonly my $PASSWD => '/etc/passwd';
Readonly my $GROUP => '/etc/group';
Readonly my $GROUP_INITIAL_CONTENTS => 'bar:x:101:unknown
test:x:102:
';
Readonly my $GROUP_EXPECTED_CONTENTS => 'bar:x:101:foo,test
test:x:50:
foo:x:100:bar,test
test2:x:51:foo
';
set_file_contents($LOGIN_DEFS,'');
set_file_contents($PASSWD,'');
set_file_contents($GROUP,$GROUP_INITIAL_CONTENTS);
$cfg = get_config_for_profile("requiredgroupmembers");
$a = $cmp->Configure($cfg);
my $group_fh = get_file($GROUP);
ok(defined($group_fh), "$GROUP successfully opened");
is("$group_fh",$GROUP_EXPECTED_CONTENTS,"$GROUP has expected contents");


done_testing();
