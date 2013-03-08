#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::accounts;
use Readonly;
use CAF::Object;
$CAF::Object::NoAction = 1;

Readonly my $PASSWD => <<EOF;
root:x:0:1:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
daemon:x:2:2:daemon:/sbin:/sbin/nologin
adm:x:3:4:adm:/var/adm:/sbin/nologin
EOF

Readonly my $GROUP => <<EOF;
bin:x:1:bin,root,daemon
root:x:0:root
sys:x:3:bin,root,adm
fuse:x:35:adm
pkics:x:36:daemon
EOF

Readonly my $SHADOW => <<'EOF';
root:$6$myveryweakpassword:15329:0:99999:7:::
bin:*:15209:0:99999:7:::
daemon:*:15209:0:99999:7:::
adm:*:15209:0:99999:7:::
EOF

Readonly::Hash my %kept_groups => (root => 1,
				   bin => 1,
				   daemon => 1);

Readonly::Hash my %kept_users => (root => 1,
				  bin => 1,
				  daemon => 1);


use constant LOGIN_DEFS => {};

=pod

=head1 DESCRIPTION

Tests for GitHub issue #2, reported by LAL.

When C<remove_unknown=true>, removing a group but leaving some of its
members around (maybe those members where in C<kept_users>), would
"resurrect" that group's data structure.  This would ultimately make
the component fail, or produce corrupted passwd or group files.

=cut

my $cmp = NCM::Component::accounts->new("accounts");

set_file_contents("/etc/passwd", $PASSWD);
set_file_contents("/etc/group", $GROUP);
set_file_contents("/etc/shadow", $SHADOW);

my $sys = $cmp->build_system_map(LOGIN_DEFS,'none');

$cmp->adjust_groups($sys, {}, \%kept_groups, 1);
ok(!exists($sys->{groups}->{fuse}), "Fuse group is removed");
ok(!exists($sys->{groups}->{pkics}), "pkics group is removed");
$cmp->adjust_accounts($sys, {}, \%kept_users, 1);
ok(!exists($sys->{groups}->{fuse}), "Fuse group is still not there");
ok(!exists($sys->{groups}->{pkics}), "pkics group still not there");

done_testing();
