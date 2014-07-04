#!/usr/bin/perl
# -*- mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(simple);
use NCM::Component::pam;
use Test::MockModule;
use CAF::Object;

plan skip_all => "Testing module not found in the system" if $@;

$CAF::Object::NoAction = 1;

my $mock = Test::MockModule->new('NCM::Component::pam');

=pod

=head1 DESCRIPTION

Test the configure() method.

=cut

my $cmp = NCM::Component::pam->new('pam');
my $cfg = get_config_for_profile('simple');

is($cmp->Configure($cfg), 1, "Configure succeeds");
my $fh = get_file("/etc/security/access.conf");
ok($fh, "A file was actually created");
isa_ok($fh, "CAF::FileWriter");
my $pf = get_file("/etc/pam.d/sshd");
ok($pf, "An /etc/pam.d file was created");
isa_ok($pf, "CAF::FileWriter");

done_testing();
