#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(groups/nokept);
use NCM::Component::accounts;
use CAF::Object;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test that the correct lines end up in the correct file.

=cut

my $cmp = NCM::Component::accounts->new('accounts');

my $cfg = get_config_for_profile('groups/nokept');

my $t = $cfg->getElement("/software/components/accounts")->getTree();

$cmp->commit_groups($t->{groups});

my $fh = get_file("/etc/group");

=pod

=head1 TEST TYPES

=head2 Memberless groups get committed

=cut

ok(defined($fh), "Correct file was written");
like($fh, qr{^root:x:0:$}m, "Correct format given to memberless groups");
$t->{groups}->{bin}->{members} = { 'foo' => 1,
				   'bar' => 1,
				   'baz' => 1};
$cmp->commit_groups($t->{groups});
$fh = get_file("/etc/group");
like($fh, qr{^bin:x:1:(?:foo|bar|baz),(?:foo|bar|baz),(?:foo|bar|baz)$}m,
     "Members of a group are correctly represented");
like($fh, qr{^(?:\w+:\w+:\w+:[\w,]*\n)+$},
     "File /etc/group has definitely a correct format");

done_testing();
