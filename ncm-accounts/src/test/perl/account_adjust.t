#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More tests => 61;
use Test::Quattor qw(users/nokept users/tochange users/adjust_accounts);
use NCM::Component::accounts;
use CAF::Reporter;
use CAF::Object;
use English;

$CAF::Object::NoAction = 1;

sub users_in
{
    my ($u) = @_;
    return scalar(keys(%{$u->{passwd}})) || scalar(keys(%{$u->{users}}));
}

sub groups_in
{
    my ($gl) = @_;
    return scalar(keys(%{$gl->{groups}}));
}

use constant GROUP_CONTENTS => <<EOF;
root:x:0:
bin:x:1:bin,daemon
daemon:x:2:bin,daemon,fubar
foo:x:2:fubar
gtest:x:1200:
EOF

use constant PASSWD_CONTENTS => <<EOF;
root:x:0:0:comment for root:homeforroot:rootshell
bin:x:1:1:comment for bin:homeforbin:binshell
daemon:x:2:2:comment for daemon:homefordaemon:daemonshell
fubar:x:3:2:comment for fubar:homeforfubar:fubarshell
utest:x:1500:2:comment for utest:homeforutest:utestshell
EOF

use constant SHADOW_CONTENTS => <<EOF;
root:apassword:15329:0:99999:7:::
bin:*:15209:0:99999:7:::
daemon:*:15209:0:99999:7:::
EOF

use constant LOGIN_DEFS => {};
use constant LD_UID_GID_MAX => {uid_min => 2,
                                uid_max => 1000,
                                gid_min => 1,
                                gid_max => 2000 };
use constant LD_ALL_PRESERVED => {uid_min => 2,
                                  uid_max => 2000,
                                  gid_min => 1,
                                  gid_max => 2000 };
use constant LD_UID_GID_CONFUSION => {uid_min =>1,
                                      uid_max => 2000,
                                      gid_min => 2,
                                      gid_max => 1000 };

set_file_contents("/etc/passwd", PASSWD_CONTENTS);
set_file_contents("/etc/group", GROUP_CONTENTS);
set_file_contents("/etc/shadow", SHADOW_CONTENTS);

my $cmp = NCM::Component::accounts->new('accounts');

my $sys = $cmp->build_system_map(LOGIN_DEFS,'none');


=pod

=head1 DESCRIPTION

Test how accounts get removed and added from a system.

=head1 TESTS

=head2 C<delete_account>

Test how a single account is removed from a system.

=over

=item When it doesn't exist

This shouldn't happen, but it's good to ensure that bad situations
don't corrupt the system

=cut

my ($u, $g) = (users_in($sys), groups_in($sys));

$cmp->delete_account($sys, "ouihljhljh");
is(users_in($sys), $u, "Removing a non-existing account doesn't affect the valid ones");
is(groups_in($sys), $g, "Removing a non-existing account doesn't affect any groups");

=pod

=item When it has no associated groups

=cut


$cmp->delete_account($sys, "root");
ok(!exists($sys->{passwd}->{root}), "groupless account removed");
is(users_in($sys), 4,
   "Valid accounts preserved after removal of groupless account");
is(groups_in($sys), 5,
   "Groups not modified after removal of groupless account");

=pod

=item When it belongs to groups that need to be re-adjusted

=cut

$cmp->delete_account($sys, "bin");
ok(!exists($sys->{passwd}->{bin}), "Account successfully removed");
foreach my $g (qw(bin daemon)) {
    ok(!exists($sys->{groups}->{$g}->{members}->{bin}),
       "Account bin successfully removed from group $g");
}
is(users_in($sys), 3, "Valid accounts have not been removed");

=pod

=item * When one of the groups it belonged to was scheduled for removal

=cut

delete($sys->{groups}->{foo});
$cmp->delete_account($sys, "fubar");
ok(!exists($sys->{passwd}->{fubar}), "Account successfully deleted");
ok(!exists($sys->{groups}->{foo}), "Removed group is not resurrected by mistake");

is(users_in($sys), 2, "All unneeded accounts have been removed");
is(groups_in($sys), 4, "No groups are resurrected");

=cut

=pod

=back

=head2 C<delete_unneeded_accounts>

Remove any accounts from the system that shouldn't be there, by:

=over

=item Removing accounts that are not in the profile, with no kept list

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
my $cfg = get_config_for_profile('users/nokept');
my $t = $cfg->getElement("/software/components/accounts")->getTree();
$t->{users} = $cmp->compute_desired_accounts($t->{users});
$cmp->delete_unneeded_accounts($sys, $t->{users});
ok(exists($sys->{passwd}->{root}), "root account is never ever removed");
is(users_in($sys), 1,
   "Accounts in the system but not in the profile get removed (excepting root)");

=pod

=item Preserving accounts that are in the system and in the profile

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$t->{users}->{daemon} = $sys->{passwd}->{daemon};
$cmp->delete_unneeded_accounts($sys, $t->{users}, {bin => 1,
						   foobar => 1});
is(users_in($sys), 3,
   "Accounts in the profile remain in the system");
delete($t->{users}->{daemon});

=pod

=item Removing only accounts that are not in the profile nor in the
kept list

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$cmp->delete_unneeded_accounts($sys, $t->{users}, {bin => 1,
						   foobar => 1});

ok(exists($sys->{passwd}->{root}),
   "root account is respected even if there is a kept list without it");
ok(exists($sys->{passwd}->{bin}),
   "Account from the kept list stays in the system");
is(users_in($sys), 2, "Only preserved accounts remain in the system");


=pod

=back

=head2 C<add_account>

Add a single account to a system that doesn't have it already. It
means:

=over

=item Report errors when accounts belong to unknown groups

An account must belong to a group that is either in the profile (and
thus is going to be created) or in the system (and is going to be
preserved) or in both.

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$t = $cfg->getElement("/software/components/accounts")->getTree();
ok(!exists($sys->{groups}->{$t->{users}->{nopool}->{groups}->[0]}),
   "Account nopool really has no valid groups");
$cmp->add_account($sys, 'nopool', $t->{users}->{nopool});
is($cmp->{ERROR}, 1, "Account with no valid groups raises an error");
ok(!exists($sys->{passwd}->{nopool}), "Account with no valid groups is not added");

=pod

=item Add an account whose group was in the system but not in
/etc/group

For instance, adding a local account to a group that comes present
from LDAP

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$g = getgrgid($GID);
$t->{users}->{nopool}->{groups} = [$g];
$cmp->add_account($sys, 'nopool', $t->{users}->{nopool});
ok(exists($sys->{passwd}->{nopool}),
   "Account with a valid group out of /etc/group is added");

=pod

=item Add an account with valid group to the system

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$u = users_in($sys);

$cmp->{ERROR} = 0;

$t->{users}->{nopool}->{groups} = ['root'];
$cmp->add_account($sys, 'nopool', $t->{users}->{nopool});
is($cmp->{ERROR}, 0, "Addition succeeded");
is(users_in($sys), $u+1, "Addition really succeded");
ok(exists($sys->{passwd}->{nopool}), "Account nopool really added");
ok(exists($sys->{groups}->{root}->{members}->{nopool}),
   "Account nopool added to its group");
is($sys->{passwd}->{nopool}->{main_group}, 0, "Account's main group correctly chosen");


=pod

=item An account with a purely numeric GID gets added, no matter what

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$t->{users}->{nopool}->{groups} = [42424242];
$cmp->add_account($sys, 'nopool', $t->{users}->{nopool});
ok(exists($sys->{passwd}->{nopool}), "Account nopool really added with numeric ID");
foreach my $i (values(%{$sys->{groups}})) {
    ok(!exists($i->{members}->{nopool}), "Account nopool not added to $i->{name}");
}
is($sys->{passwd}->{nopool}->{main_group}, $t->{users}->{nopool}->{groups}->[0],
   "Numeric GID correctly added");

=pod

=item An account with no password is locked

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
delete($t->{users}->{nopool}->{password});
$cmp->add_account($sys, 'nopool', $t->{users}->{nopool});
is($sys->{passwd}->{nopool}->{password}, "!", "Account with no password is locked");

=pod

=back

=head2 C<add_profile_accounts>

In this case, accounts from the system and the profile get merged. We
have to ensure:

=over

=cut

$t = $cfg->getElement("/software/components/accounts")->getTree();
$t->{users} = $cmp->compute_desired_accounts($t->{users});
$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$cmp->{ERROR} = 0;
$cmp->add_profile_accounts($sys, $t->{users});

=pod

=item Accounts that should fail still fail

Accounts with no associated group fail always.

=cut

is($cmp->{ERROR}, 1, "An error was detected when processing the profile");
ok(!exists($sys->{passwd}->{nopool}), "Invalid account was not added by add_profile_accounts");

=pod

=item Valid accounts are all added

=cut

foreach my $u (grep(m{^pool}, keys(%{$t->{users}}))) {
    ok(exists($sys->{passwd}->{$u}), "Valid user $u is added");
}

=pod

=item We can change arbitrary fields

=cut


$cfg = get_config_for_profile('users/tochange');
$t = $cfg->getElement("/software/components/accounts")->getTree();

$cmp->add_profile_accounts($sys, $t->{users});
is($sys->{passwd}->{pool03}->{uid}, 53, "Accounts get modified properly");
is($sys->{passwd}->{pool05}->{password}, "veryspecialpassword",
   "Passwords get correctly modified");
is($sys->{passwd}->{pool03}->{main_group}, $sys->{groups}->{bin}->{gid},
   "User pool03 gets reassigned to the correct main group when its groups change");
foreach my $g (qw(bin daemon)) {
    ok(exists($sys->{groups}->{$g}->{members}->{pool03}),
       "Group pool03 added to the correct group $g");
}

=pod

=item Accounts with no password keep the one already present in the system

This is needed, f.i, when setting an account's password with SINDES.

=cut

is($sys->{passwd}->{pool03}->{password}, "anotherpassword",
   "Passwords from the system are reused when not defined in the profile");

=pod

=back

=head2 C<adjust_accounts>

Test how accounts are added and removed

=over

=item When C<remove_unknown> is false

Accounts in the system must be preserved, independently of the value of C<kept_users>

=cut

$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
ok(exists($sys->{groups}->{daemon}->{members}->{fubar}),
   "Account from ldap is part of the tree");
$cfg = get_config_for_profile('users/adjust_accounts');
$t = $cfg->getElement("/software/components/accounts")->getTree();
$u = users_in($sys) + users_in($t);
$cmp->adjust_accounts($sys, $t->{users});
is(users_in($sys), $u,
   "New users added while old ones preserved in absence of remove_unknown");
$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$cmp->adjust_accounts($sys, $t->{users}, { bin => 1, baz => 1});
is(users_in($sys), $u,
   "New users added while old ones preserved in absence of remove_unknown, with kept_users");
ok(exists($sys->{groups}->{daemon}->{members}->{fubar}),
   "Group member from an external account source (like LDAP) stays when not remove_unknown");
$sys = $cmp->build_system_map(LOGIN_DEFS,'none');

=pod

=item When C<remove_unknonw> is true and preserved_accounts=none (or undef)

Only root, accounts in the profile, or accounts in C<kept_users> list
that already existed, must stay.

=cut

$cmp->adjust_accounts($sys, $t->{users}, {}, 1);
is(users_in($sys), users_in($t)+1,
   "Users not in the profile (except root) are removed");
$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
$cmp->adjust_accounts($sys, $t->{users}, {daemon => 1}, 1);
is(users_in($sys), users_in($t)+2,
   "Users not in the profile (except root or kept ones) are removed");
ok(!exists($sys->{groups}->{daemon}->{members}->{fubar}),
   "Users coming from LDAP are removed from local groups if remove_unknown is true and they are not in the profile");


=pod

=item When C<remove_unknonw> is true and preserved_accounts=dyn_user_groups

Only root, accounts in the profile,  accounts in C<kept_users> list
that already existed, and accounts not in the profile but with a uid <= UID_MAX must stay.

=cut

$sys = $cmp->build_system_map(LD_UID_GID_MAX, 'dyn_user_group');
$cmp->adjust_accounts($sys, $t->{users}, {daemon => 1}, 1, 'dyn_user_group');
is(users_in($sys), users_in($t)+4,
   "Users not in the profile with non preserved UIDs removed");
$sys = $cmp->build_system_map(LD_ALL_PRESERVED, 'dyn_user_group');
$cmp->adjust_accounts($sys, $t->{users}, {daemon => 1}, 1, 'dyn_user_group');
is(users_in($sys), users_in($t)+5,
   "All users with preserved UIDs");
$sys = $cmp->build_system_map(LD_UID_GID_CONFUSION, 'dyn_user_group');
$cmp->adjust_accounts($sys, $t->{users}, {daemon => 1}, 1, 'dyn_user_group');
is(users_in($sys), users_in($t)+5,
   "Users not in the profile with non preserved UIDs removed, no UID_MAX/GID_MAX confusion");


=pod

=item When C<remove_unknonw> is true and preserved_accounts=system

Only root, accounts in the profile,  accounts in C<kept_users> list
that already existed, and accounts not in the profile but with a uid <= UID_MIN must stay.

=cut

$sys = $cmp->build_system_map(LD_UID_GID_MAX, 'system');
$cmp->adjust_accounts($sys, $t->{users}, {daemon => 1}, 1, 'system');
is(users_in($sys), users_in($t)+3,
   "Users not in the profile with non system UIDs removed");
$sys = $cmp->build_system_map(LD_UID_GID_CONFUSION, 'system');
$cmp->adjust_accounts($sys, $t->{users}, {daemon => 1}, 1, 'system');
is(users_in($sys), users_in($t)+2,
   "Users not in the profile with non system UIDs removed, no UID_MIN/GID_MIN confusion");


done_testing();
