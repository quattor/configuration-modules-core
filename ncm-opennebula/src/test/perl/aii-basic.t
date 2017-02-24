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
use Test::Quattor qw(aii-basic);
use OpennebulaMock;
use NCM::Component::opennebula;

$CAF::Object::NoAction = 1;

my $opennebulaaii = new Test::MockModule('NCM::Component::OpenNebula::AII');

$opennebulaaii->mock('read_one_aii_conf', Net::OpenNebula->new(url  => "http://localhost/RPC2",
                                                      user => "oneadmin",));
$opennebulaaii->mock('is_timeout', undef);


my $cfg = get_config_for_profile('aii-basic');

my $aii = NCM::Component::opennebula->new();
is (ref ($aii), "NCM::Component::opennebula", "AII NCM::Component::opennebula correctly instantiated");

my $one = $aii->read_one_aii_conf();
is (ref($one), "Net::OpenNebula", "returns Net::OpenNebula instance (mocked)");

my $path;
# test remove
rpc_history_reset;

$path = "/system/aii/hooks/remove/0";
$aii->aii_remove($cfg, $path);
#diag_rpc_history;
ok(rpc_history_ok(["one.vmpool.info",
                   "one.templatepool.info",
                   "one.template.delete",
                   "one.imagepool.info",
                   "one.image.delete",
                   "one.imagepool.info",
                   "one.vnpool.info",
                   "one.vn.info",
                   "one.vn.rm_ar",
                   "one.vnpool.info"]),
                   "remove rpc history ok");
# test configure
rpc_history_reset;

$path = "/system/aii/hooks/configure/0";
$aii->aii_configure($cfg, $path);
#diag_rpc_history;
ok(rpc_history_ok(["one.imagepool.info",
                   "one.imagepool.info",
                   "one.datastorepool.info",
                   "one.image.allocate",
                   "one.image.info",
                   "one.image.chmod",
                   "one.userpool.info",
                   "one.grouppool.info",
                   "one.image.chown",
                   "one.vnpool.info",
                   "one.vn.info",
                   "one.vnpool.info",
                   "one.templatepool.info",
                   "one.template.update",
                   "one.template.chmod",
                   "one.userpool.info",
                   "one.grouppool.info",
                   "one.template.chown"]),
                   "configure rpc history ok");

# test ks install
rpc_history_reset;

$path = "/system/aii/hooks/install/0";
$aii->aii_install($cfg, $path);
#diag_rpc_history;
ok(rpc_history_ok(["one.vmpool.info",
                   "one.templatepool.info",
                   "one.imagepool.info",
                   "one.image.info",
                   "one.template.instantiate"]),
                   "install rpc history ok");

done_testing();
