#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;

use Test::More;
use Test::Quattor qw(simple);
use NCM::Component::nss;
use Test::MockModule;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $mock = Test::MockModule->new('NCM::Component::nss');

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut

my $cmp = NCM::Component::nss->new('nss');
my $cfg = get_config_for_profile('simple');
my $testfile = "/etc/nsswitch.conf";
my $testcmd = "/usr/sbin/buildldap -d passwd";

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file($testfile);
ok($fh, "$testfile was created");
isa_ok($fh, "CAF::FileWriter");
like("$fh", qr{^passwd: files ldap$}m, "passwd line present and correct");
ok(defined(get_command($testcmd)), "$testcmd was run");
ok(!defined(get_command('/usr/sbin/builddb')), "inactive db was not built");

done_testing();
