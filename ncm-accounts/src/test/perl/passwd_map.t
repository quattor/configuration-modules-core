#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::accounts;

=pod

=head1 DESCRIPTION

Test how the basic map of users and groups is generated from
/etc/group, /etc/passwd and /etc/shadow

=head1 TESTS

=cut

use constant GROUP_CONTENTS => <<EOF;
root:x:0:
bin:x:1:bin,daemon
daemon:x:2:bin,daemon
EOF

use constant PASSWD_CONTENTS => <<EOF;
root:x:uidforroot:groupforroot:comment for root:homeforroot:rootshell
bin:x:uidforbin:groupforbin:comment for bin:homeforbin:binshell
daemon:x:uidfordaemon:groupfordaemon:comment for daemon:homefordaemon:daemonshell
EOF

set_file_contents("/etc/group", GROUP_CONTENTS);
set_file_contents("/etc/passwd", PASSWD_CONTENTS);

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

is(scalar(keys($g->{root}->{members})), 0,
   "root group didn't receive any members");
foreach my $i (qw(bin daemon)) {
    is(scalar(keys($g->{$i}->{members})), 2,
       "Group $i received the correct amount of members");
    foreach my $j (qw(bin daemon)) {
	ok(exists($g->{$i}->{members}->{$j}), "Group $i received member $j");
    }
}

is($g->{root}->{gid}, 0, "root received the correct gid");
is($g->{bin}->{gid}, 1, "bin received the correct gid");
is($g->{daemon}->{gid}, 2, "daemon received the correct gid");

=pod

=head2 PASSWD MAPPING

Test the creation of existing users' maps out of /etc/passwd, together
with the group information already gathered.

=cut

my $u = $cmp->build_passwd_map($g);
is(scalar(keys(%$u)), 3, "Correct amount of users mapped");

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
}

ok(!exists($u->{root}->{groups}),
   "root account is not listed in any further groups");
is(scalar(@{$u->{bin}->{groups}}), 2,
   "bin account listed in the correct groups");
ok(grep("bin", @{$u->{bin}->{groups}}), "bin is listed in the bin group");
ok(grep("daemon", @{$u->{bin}->{groups}}), "bin is listed in the daemon group");

done_testing();
