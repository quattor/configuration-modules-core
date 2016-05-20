#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simpleaccounts requiredgroupmembers poolaccounts);
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

Readonly my $GROUP_INITIAL_CONTENTS => 'bar:x:101:baz
bar2:x:102:baz
test:x:103:
';

# both users are non preserved UIDs (> UID_MAX), foo2 is a group required members but should
# be removed as it is not preserved.
Readonly my $PASSWD_INITIAL_CONTENTS => 'user1:x:200:102:comment for user1:user1home:user1shell
foo2:x:201:101:comment for foo2:foo2home:foo2shell
';

Readonly my $LOGIN_DEFS_CONTENTS => 'UID_MIN 500
UID_MAX 110
GID_MIN 50
GID_MAX 110
';

# Expected /etc/group with resetMembers=true for group bar
Readonly my $GROUP_EXPECTED_CONTENTS => 'bar:x:101:foo2,test
bar2:x:102:foo,test
test:x:50:
foo:x:100:bar,test
test2:x:51:foo
';

# Expected /etc/passwd (check that group required members have no effect)
Readonly my $PASSWD_EXPECTED_CONTENTS => 'root:x:0:0:root:/root:/bin/bash
';

set_file_contents($LOGIN_DEFS,$LOGIN_DEFS_CONTENTS);
set_file_contents($PASSWD,$PASSWD_INITIAL_CONTENTS);
set_file_contents($GROUP,$GROUP_INITIAL_CONTENTS);
$cfg = get_config_for_profile("requiredgroupmembers");
$a = $cmp->Configure($cfg);
my $group_fh = get_file($GROUP);
ok(defined($group_fh), "$GROUP successfully opened");
is("$group_fh",$GROUP_EXPECTED_CONTENTS,"$GROUP has expected contents (replaceMembers=true)");
my $passwd_fh = get_file($PASSWD);
ok(defined($passwd_fh), "$PASSWD successfully opened");
is("$passwd_fh",$PASSWD_EXPECTED_CONTENTS,"$PASSWD has expected contents with group required members");

$group_fh->close();
$passwd_fh->close();

done_testing();
