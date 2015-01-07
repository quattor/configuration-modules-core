#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;

use Test::More;
use Test::Quattor qw(simple);
use NCM::Component::sysctl;
use Test::MockModule;
use CAF::Object;

$CAF::Object::NoAction = 1;

my $mock = Test::MockModule->new('NCM::Component::sysctl');

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut


my $cmp = NCM::Component::sysctl->new('sysctl');
my $cfg = get_config_for_profile('simple');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/etc/sysctl.d/50-quattor");
ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");
like("$fh", qr{^kernel.sysrq = 1$}m, "Found kernel.sysrq variable");

done_testing();
