# -* mode: cperl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor qw(opennebula);
use CAF::Object;
use Test::MockModule;
use CAF::FileWriter;

use OpennebulaMock;

use NCM::Component::opennebula;

# Test mocked getpwnam
is($NCM::Component::OpenNebula::Server::ONEADMINUSR, 3, "One admin user id");
is($NCM::Component::OpenNebula::Server::ONEADMINGRP, 4, "One admin group id");

$CAF::Object::NoAction = 1;

# Set OpenNebula file version
set_file_contents("/var/lib/one/remotes/VERSION", "5.0.0");

my $cmp = NCM::Component::opennebula->new("opennebula");

my $cfg = get_config_for_profile("opennebula");
my $tree = $cfg->getElement("/software/components/opennebula")->getTree();
my $one = $cmp->make_one($tree->{rpc});
# Set ssh multiplex options
$cmp->set_ssh_command(1);

# Test ONE RPC component
rpc_history_reset;
$cmp->Configure($cfg);
#diag_rpc_history;
ok(rpc_history_ok(["one.system.version"]), "Configure opennebula rpc endpoint history ok");

ok(!exists($cmp->{ERROR}), "No errors found in normal execution");

is($NCM::Component::opennebula::ONED_CONF_FILE, "/etc/one/oned.conf", "expected oned.conf filename");

my $fh = get_file($NCM::Component::opennebula::ONED_CONF_FILE);
isa_ok($fh, "CAF::FileWriter", "oned.conf CAF::FileWriter instance");
# only test one entry, the remainder is verified with the TT unittests
like("$fh", qr{^DB\s?=\s?\[$}m, "oned.conf has expected content");
$fh->close();

# one_auth file
is($NCM::Component::OpenNebula::Server::ONEADMIN_AUTH_FILE, "/var/lib/one/.one/one_auth", "expected one_auth filename");
my $fhauth = get_file($NCM::Component::OpenNebula::Server::ONEADMIN_AUTH_FILE);
isa_ok($fhauth, "CAF::FileWriter", "one_auth CAF::FileWriter instance");
like("$fhauth", qr{^oneadmin\:.+$}m, "one_auth has expected content");
$fhauth->close();

# serveradmin files
is($NCM::Component::OpenNebula::Server::SERVERADMIN_AUTH_DIR, "/var/lib/one/.one/", "expected serveradmin auth directory");
foreach my $service (@NCM::Component::OpenNebula::Server::SERVERADMIN_AUTH_FILE) {
    my $auth_file = $NCM::Component::OpenNebula::Server::SERVERADMIN_AUTH_DIR . $service;
    my $fhserver = get_file($auth_file);
    isa_ok($fhserver, "CAF::FileWriter", "serveradmin $service auth CAF::FileWriter instance");
    like("$fhserver", qr{^serveradmin\:.+$}m, "serveradmin $service file has expected content");
    $fhserver->close();
}

# suntone conf file
my $sunstone = get_file($NCM::Component::opennebula::SUNSTONE_CONF_FILE);
isa_ok($sunstone, "CAF::FileWriter", "sunstone-server.conf CAF::FileWriter instance");
like("$sunstone", qr{^:host:\s{1}.+$}m, "sunstone-server.conf has expected content");
$sunstone->close();

# oneflow conf file
my $oneflow = get_file($NCM::Component::opennebula::ONEFLOW_CONF_FILE);
isa_ok($oneflow, "CAF::FileWriter", "oneflow-server.conf CAF::FileWriter instance");
like("$oneflow", qr{^:shutdown_action:\s{1}.+$}m, "oneflow-server.conf has expected content");
$oneflow->close();

# kvmrc conf file
my $kvmrc = get_file($NCM::Component::OpenNebula::Server::KVMRC_CONF_FILE);
isa_ok($kvmrc, "CAF::FileWriter", "kvmrc CAF::FileWriter instance");
like("$kvmrc", qr{^export\s{1}FORCE_DESTROY=.+$}m, "kvmrc has expected content");
$kvmrc->close();

# vnm conf file
my $vnm_conf = get_file($NCM::Component::OpenNebula::Server::VNM_CONF_FILE);
isa_ok($vnm_conf, "CAF::FileWriter", "vnm_conf CAF::FileWriter instance");
like("$vnm_conf", qr{^:arp_cache_poisoning:\s{1}.+$}m, "vnm_conf has expected content");
$vnm_conf->close();

done_testing();
