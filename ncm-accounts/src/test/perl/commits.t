#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::accounts;
use CAF::Object;
require Test::NoWarnings;

$CAF::Object::NoAction = 1;

use constant GROUP => <<EOF;
root:x:0:
bin:x:1:
daemon:x:2
EOF

use constant PASSWD => <<EOF;
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/bin:/sbin/nologin
foo:x:1000:100::/home/foo:/bin/bash
bar:x:1001:100:bar::/bin/bash
baz:x:1002:100:::
EOF

use constant SHADOW => <<EOF;
root:rootpassword:0:0:0:::
bin:binpassword:5:6:7:::
foo:foonpassword:1:2:3:::
bar:foonpassword:1:2:3:::
baz:*:1:2:3:::
EOF




set_file_contents("/etc/group", GROUP);
set_file_contents("/etc/passwd", PASSWD);
set_file_contents("/etc/shadow", SHADOW);

=pod

=head1 DESCRIPTION

Test that the correct lines end up in the correct file.

=cut

my $cmp = NCM::Component::accounts->new('accounts');

my $sys = $cmp->build_system_map();

$cmp->commit_groups($sys->{groups});

my $fh = get_file("/etc/group");

=pod

=head1 TEST TYPES

=head2 Committint /etc/group

=over

=item Memberless groups are correctly formed

=cut

isa_ok($fh, "CAF::FileWriter", "A file was written");
like($fh, qr{^root:x:0:$}m, "Correct format given to memberless groups");
$sys->{groups}->{bin}->{members} = { 'foo' => 1,
				   'bar' => 1,
				   'baz' => 1};
$cmp->commit_groups($sys->{groups});
$fh = get_file("/etc/group");

=pod

=item Groups with members are committed

=cut

like($fh, qr{^bin:x:1:(?:foo|bar|baz),(?:foo|bar|baz),(?:foo|bar|baz)$}m,
     "Members of a group are correctly represented");

=pod

=item All lines have a correct format

=cut

like($fh, qr{^(?:\w+:\w+:\w+:[\w,]*\n)+$},
     "File /etc/group has definitely a correct format");

=pod

=head2 Committing /etc/passwd and /etc/shadow

=cut

delete($sys->{passwd}->{foo}->{comment});
delete($sys->{passwd}->{bar}->{homeDir});
delete($sys->{passwd}->{baz}->{shell});
delete($sys->{passwd}->{baz}->{comment});
delete($sys->{passwd}->{baz}->{homeDir});
delete($sys->{passwd}->{baz}->{password});

$cmp->commit_accounts($sys->{passwd});

$fh = get_file("/etc/passwd");
isa_ok($fh, "CAF::FileWriter", "/etc/passwd was written");
is("$fh", PASSWD, "/etc/passwd recreated respecting line numbers");
$fh = get_file("/etc/shadow");
isa_ok($fh, "CAF::FileWriter", "/etc/shadow was written");
like("$fh", qr{^root:rootpassword:(?:.*:){6}}m, "/etc/shadow received the root account");
like("$fh", qr{^baz:\*}m, "Account without password is locked in /etc/shadow");
like("$fh", qr{^(?:(?:.*:){8}\n){5}}, "All lines correctly rendered in /etc/shadow");
is(*$fh->{options}->{mode}, 0400, "Only root may read /etc/shadow");

Test::NoWarnings::had_no_warnings();

done_testing();
