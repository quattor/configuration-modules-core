use strict;
use warnings;

use Test::More;
use Test::Quattor qw(configure configure_noserver configure_nomounts configure_daemon);
use Test::MockModule;

use Test::Quattor::RegexpTest;

use NCM::Component::nfs;

# service variant set to linux_sysv

my $mock = Test::MockModule->new('NCM::Component::nfs');
my $res = {};
my $export_arg;
$mock->mock('exports', sub {
    shift;
    $export_arg = shift;
    return $res->{exports};
});

my $process_mounts_arg;

$mock->mock('process_mounts', sub {
    shift;
    $process_mounts_arg = shift;
    return $res->{fstab_changed}, $res->{action};
});

my $cmp = NCM::Component::nfs->new('nfs');
my $cfg = get_config_for_profile('configure');
my $tree = $cfg->getTree($cmp->prefix());

command_history_reset();
is($cmp->Configure($cfg), 1, "Configure returns 1");
is_deeply($export_arg, $tree, "whole config tree passed to exports method");
is_deeply($process_mounts_arg, $tree, "whole config tree passed to process_mounts method");

ok(! command_history_ok([qr{nfs}]), 'No nfs service reload when nothing changed / no actions taken');
foreach my $change (qw(exports)){
    command_history_reset();
    $res = {$change => 1};
    is($cmp->Configure($cfg), 1, "Configure returns 1 (change $change)");
    ok(command_history_ok([qr{service nfs-server reload}]), "nfs service reload when $change changed");
};

foreach my $change (qw(fstab_changed action)){
    command_history_reset();
    $res = {$change => 1};
    is($cmp->Configure($cfg), 1, "Configure returns 1 (change $change)");
    ok(command_history_ok(undef, [qr{service nfs-server reload}]), "no nfs service reload when $change changed");
};

# noserver config
my $nosrvcfg = get_config_for_profile('configure_noserver');
foreach my $change (qw(exports fstab_changed action)){
    command_history_reset();
    $res = {$change => 1};
    is($cmp->Configure($nosrvcfg), 1, "Configure returns 1 (change $change) with server=false");
    ok(command_history_ok(undef, [qr{service nfs-server reload}]), "no nfs service reload when $change changed with server=false");
};

# noserver config
my $nomounts = get_config_for_profile('configure_nomounts');
command_history_reset();
$process_mounts_arg = undef;
is($cmp->Configure($nomounts), 1, "Configure returns 1 without mounts");
ok(!defined($process_mounts_arg), "no nfs process_mounts without mounts");

# configure with alternative daemon set
my $cfgdaemon = get_config_for_profile('configure_daemon');
foreach my $change (qw(exports)){
    command_history_reset();
    $res = {$change => 1};
    is($cmp->Configure($cfgdaemon), 1, "Configure returns 1 (change $change)");
    ok(command_history_ok([qr{service nfs-kernel-server reload}]), "nfs-server service reload when $change changed");
};

done_testing();
