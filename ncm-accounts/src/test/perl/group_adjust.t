#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(groups/nokept groups/remove_unknown);
use NCM::Component::accounts;

sub groups_in
{
    my ($gl) = @_;
    return scalar(keys(%{$gl->{groups}}));
}

=pod

=head1 DESCRIPTION

Test how groups are adjusted between the system and the profile.

=head1 TESTS

=cut


use constant GROUP_CONTENTS => <<EOF;
g1:x:42
g2:x:43:a,b,c
EOF

my $cmp = NCM::Component::accounts->new('accounts');
set_file_contents("/etc/group", GROUP_CONTENTS);
my $sys = { groups => $cmp->build_group_map() };
my $cfg = get_config_for_profile('groups/nokept');

my $t = $cfg->getElement("/software/components/accounts")->getTree();

=pod

=head2 C<delete_groups>

This method only removes groups that are deemed innecessary. That is:

=over

=item In absence of any kept groups, groups in the system that are not
in the profile should be removed.

=cut


$cmp->delete_groups($sys, $t);

is(groups_in($sys), 0, "All outdated groups are gone");
$sys = { groups => $cmp->build_group_map() };

=pod

=item If there are any kept groups, they are kept, regardless of the
profile.

=cut

$cmp->delete_groups($sys, $t, {"g1" => 1});
is(groups_in($sys), 1, "Kept groups are preserved");
ok(exists($sys->{groups}->{g1}), "Kept group g1 is really kept");

=pod

=item If a group exists in both the system and the profile, it is
kept, regardless of what is kept.

=cut

$t->{groups}->{g1}->{gid} = 345;
$cmp->delete_groups($sys, $t->{groups});
is(groups_in($sys), 1,
   "Groups in the profile are preserved, even without kept_groups");
ok(exists($sys->{groups}->{g1}), "Correct group was preserved");
$sys = { groups => $cmp->build_group_map() };
$cmp->delete_groups($sys, $t->{groups}, {g1 => 1});
is(groups_in($sys), 1,
   "Groups in the profile are preserved with kept_groups");
ok(exists($sys->{groups}->{g1}),
   "Correct group was preserved with kept_groups");

=pod

=back

=head2 C<apply_profile_groups>

This method only adds groups that are in the profile but not in the
system, or readjusts the GID of any groups in both.

=cut

$cmp->apply_profile_groups($sys, $t->{groups});
is(groups_in($sys), 4,
   "Groups in the profile were correctly added");
is($sys->{groups}->{g1}->{gid}, $t->{groups}->{g1}->{gid},
   "System group g1 had its gid updated");

$t->{groups}->{g1}->{gid} = 9878;
$cmp->apply_profile_groups($sys, $t->{groups});
is($sys->{groups}->{g1}->{gid}, 9878,
   "Group g1 changed its gid");

=pod

=head2 C<adjust_groups>

Mix together C<delete_groups> and C<adjust_profile_groups>. We must
verify how the C<remove_unknown> flag is handled.

=cut

$cfg = get_config_for_profile("groups/remove_unknown");
$sys = { groups =>  $cmp->build_group_map()};
$t = $cfg->getElement("/software/components/accounts")->getTree();

=pod

=over

=item Nothing is preserved, but C<remove_unknown> is false

Nothing should be deleted anyways

=cut

my $expected_groups = groups_in($sys) +
  groups_in($t);

$cmp->adjust_groups($sys, $t->{groups});
is(groups_in($sys), $expected_groups,
   "Both groups from the system and from the profile will be applied");

=pod

=item Nothing is preserved, with C<remove_unknown> being true

Only groups in the profile are found.

=cut

$sys->{groups} = $cmp->build_group_map();
$expected_groups = groups_in($t);
$cmp->adjust_groups($sys, $t->{groups}, {}, 1);
is(groups_in($sys), $expected_groups,
   "Outdated groups are removed with remove_unknown");
foreach my $i (keys(%{$t->{groups}})) {
    ok(exists($sys->{groups}->{$i}),
       "Profile group $i introduced into the system");
}

=pod

=item A group is preserved, C<remove_unknown> being true

Groups from the profile should be in place, too

=cut

$sys->{groups} = $cmp->build_group_map();
$expected_groups += scalar(keys(%{$t->{kept_groups}}));
$cmp->adjust_groups($sys, $t->{groups}, $t->{kept_groups}, 1);
is(groups_in($sys), $expected_groups,
   "Kept groups and remove_unknown mix together");
foreach my $i (keys(%{$t->{groups}}), keys(%{$t->{kept_groups}})) {
    ok(exists($sys->{groups}->{$i}), "Group $i is kept or added");
}

done_testing();

=pod

=back

=cut
