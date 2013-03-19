#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::accounts;
use CAF::Object;
$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test how the basic map of users and groups is generated from
/etc/group, /etc/passwd and /etc/shadow

=head1 TESTS

=cut

use constant GROUP_CONTENTS => <<EOF;
root:x:0:
bin:x:1:bin,daemon
daemon:x:2:bin,daemon,fubarr
EOF

use constant PASSWD_CONTENTS => <<EOF;
root:x:uidforroot:groupforroot:comment for root:homeforroot:rootshell
bin:x:uidforbin:groupforbin:comment for bin:homeforbin:binshell
daemon:x:uidfordaemon:groupfordaemon:comment for daemon:homefordaemon:daemonshell
EOF

use constant NIS_PASSWD_CONTENTS => PASSWD_CONTENTS .
    "\n+nisusr:x:uidfornisusr:groupfornisusr:commentfornisusr:homefornis:nisshell";



use constant SHADOW_CONTENTS => <<EOF;
root:apassword:15329:0:99999:7:::
bin:*:15209:0:99999:7:::
daemon:*:15209:0:99999:7:::
EOF

use constant NIS_SHADOW_CONTENTS => PASSWD_CONTENTS .
    "\n+nisusr:nispwd:5:6:8:::\n";


use constant LOGIN_DEFS => {};

set_file_contents("/etc/group", GROUP_CONTENTS);
set_file_contents("/etc/passwd", PASSWD_CONTENTS);
set_file_contents("/etc/shadow", SHADOW_CONTENTS);

my $cmp = NCM::Component::accounts->new("accounts");

=pod

=head2 GROUP MAPPING

Test the group mapping alone. Groups with users and without users are
tested.

=cut

my $g = $cmp->build_group_map();

foreach my $i (qw(root bin daemon)) {
    ok(exists($g->{$i}), "Group $i mapped");
    is($g->{$i}->{name}, $i, "Group $i 's name correctly set");
}
is(scalar(keys(%$g)), 3, "Exact groups mapped");

is(scalar(keys(%{$g->{root}->{members}})), 0,
   "root group didn't receive any members");
is(scalar(keys(%{$g->{bin}->{members}})), 2,
   "Group bin received the correct amount of members");
ok(exists($g->{bin}->{members}->{bin}), "Group bin received user bin");
ok(exists($g->{bin}->{members}->{daemon}), "Group bin received user daemon");
is(scalar(keys(%{$g->{daemon}->{members}})), 3,
   "Group daemon received the correct amount of members");
ok(exists($g->{daemon}->{members}->{bin}), "Group bin received user bin");
ok(exists($g->{daemon}->{members}->{daemon}), "Group bin received user daemon");
ok(exists($g->{daemon}->{members}->{fubarr}), "Group bin received LDAP-only account");

is($g->{root}->{gid}, 0, "root received the correct gid");
is($g->{bin}->{gid}, 1, "bin received the correct gid");
is($g->{daemon}->{gid}, 2, "daemon received the correct gid");

=pod

=head2 PASSWD MAPPING

Test the creation of existing users' maps out of /etc/passwd, together
with the group information already gathered.

=cut

my $u = $cmp->build_passwd_map($g);
is(scalar(keys(%$u)), 4, "Correct amount of users mapped");
ok(exists($u->{_passwd_special_lines_}), "One entry is added for 'special' lines");
is(scalar(@{$u->{_passwd_special_lines_}}), 0,
   "No special entries created without NIS entries");

foreach my $i (qw(root bin daemon)) {
    my $user = $u->{$i};
    ok(defined($user), "User $i created");
    is($user->{name}, $i, "User $i received the correct name");
    is($user->{uid}, "uidfor$i", "User $i received the correct id");
    is($user->{comment}, "comment for $i",
       "User $i got the correct comment");
    is($user->{main_group}, "groupfor$i",
       "User $i received the correct main group");
    is($user->{shell}, $i . "shell", "User $i received the correct shell");
    is($user->{homeDir}, "homefor$i", "User $i received the correct home");
    ok(!exists($user->{password}),
       "Password not set before reading /etc/shadow");
}

ok(!exists($u->{root}->{groups}),
   "root account is not listed in any further groups");
is(scalar(@{$u->{bin}->{groups}}), 2,
   "bin account listed in the correct groups");
ok(grep("bin", @{$u->{bin}->{groups}}), "bin is listed in the bin group");
ok(grep("daemon", @{$u->{bin}->{groups}}), "bin is listed in the daemon group");

=pod

=head3 Handling of special lines

Lines that might come from some NIS netgroup

=cut

set_file_contents("/etc/passwd", NIS_PASSWD_CONTENTS);

$u = $cmp->build_passwd_map($g);

is(scalar(@{$u->{_passwd_special_lines_}}), 1, "NIS account stored as special");

=pod

=head2 SHADOW PASSWORD HANDLING

Passwords should be read from /etc/shadow and set accordingly.

=cut

$cmp->add_shadow_info($u);
is($u->{root}->{password}, "apassword", "Root got the correct password");
is($u->{bin}->{password}, "*", "Locked password is correctly set");

ok(exists($u->{_shadow_special_lines_}),
   "No shadow special lines field always created");
is(scalar(@{$u->{_shadow_special_lines_}}), 0,
   "No shadow special lines found");


=pod

=head3 Handling of shadow entries for NIS accounts

=cut

set_file_contents("/etc/shadow", NIS_SHADOW_CONTENTS);

$cmp->add_shadow_info($u);
is(scalar(@{$u->{_shadow_special_lines_}}), 1,
   "Shadow special lines defined if there are NIS accounts");

=pod

=head2 MAP CREATION ALTOGETHER

The map the component creates out of the three files should contain
all the desired information.

=cut

set_file_contents("/etc/passwd", PASSWD_CONTENTS);
set_file_contents("/etc/shadow", SHADOW_CONTENTS);

my $sys = $cmp->build_system_map(LOGIN_DEFS,'none');
ok(exists($sys->{groups}), "Full system map contains groups");
ok(exists($sys->{groups}->{bin}->{members}->{bin}),
   "Groups in the full system map are correct");
ok(exists($sys->{passwd}), "Full system map contains the users");
is($sys->{passwd}->{root}->{uid}, "uidforroot",
   "Full system map contains correct users");
is($sys->{passwd}->{bin}->{password}, "*",
   "Full system map contains shadow information");
ok(!exists($sys->{passwd}->{fubarr}),
   "LDAP account assigned to a group is not introduced into passwd");
is(scalar(@{$sys->{special_lines}->{passwd}}), 0, "No special lines introduced");

=pod

=head3 Check also the handling of special lines

=cut

set_file_contents("/etc/passwd", NIS_PASSWD_CONTENTS);
set_file_contents("/etc/shadow", NIS_SHADOW_CONTENTS);
$sys = $cmp->build_system_map(LOGIN_DEFS,'none');
ok(exists($sys->{groups}->{bin}->{members}->{bin}),
   "Groups are correctly defined even with NIS-special entries");
is($sys->{passwd}->{root}->{uid}, "uidforroot",
   "System map is correct for non-NIS accounts");
is(scalar(@{$sys->{special_lines}->{passwd}}), 1, "NIS lines stored as special");

done_testing();
