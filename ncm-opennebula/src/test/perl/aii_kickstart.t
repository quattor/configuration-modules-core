#!/usr/bin/perl
# -*- mode: cperl -*-
# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

use strict;
use warnings;
use Test::More;
use Test::MockModule;
use Test::Quattor qw(aii_kickstart);
use NCM::Component::opennebula;
use NCM::Component::ks;
use CAF::FileWriter;
use CAF::Object;

use OpennebulaMock;

$CAF::Object::NoAction = 1;

my $fh = CAF::FileWriter->new("target/test/ks");
# This module simply prints to the default filehandle.
select($fh);

my $opennebulaaii = new Test::MockModule('NCM::Component::opennebula');

my $cfg = get_config_for_profile('aii_kickstart');

my $aii = NCM::Component::opennebula->new();
is (ref ($aii), "NCM::Component::opennebula", "AII NCM::Component::opennebula correctly instantiated");

my $path;
# test ks install
$path = "/system/aii/hooks/install/0";
$aii->aii_post_reboot($cfg, $path);

like($fh, qr{^yum\s-c\s/var/tmp/aii/yum/yum.conf\s-y\sinstall\sacpid}m, 'yum install acpid present');
like($fh, qr{^service\sacpid\sstart}m, 'service acpid restart present');

# close the selected FH and reset STDOUT
$fh->close();
NCM::Component::ks::ksclose;

done_testing();
