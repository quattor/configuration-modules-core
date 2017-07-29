use strict;
use warnings;

use Test::More;
use Test::Quattor qw(configure configure_noserver);
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
    ok(command_history_ok([qr{service nfs reload}]), "nfs service reload when $change changed");
};

foreach my $change (qw(fstab_changed action)){
    command_history_reset();
    $res = {$change => 1};
    is($cmp->Configure($cfg), 1, "Configure returns 1 (change $change)");
    ok(command_history_ok(undef, [qr{service nfs reload}]), "no nfs service reload when $change changed");
};

# noserver config
my $nosrvcfg = get_config_for_profile('configure_noserver');
foreach my $change (qw(exports fstab_changed action)){
    command_history_reset();
    $res = {$change => 1};
    is($cmp->Configure($nosrvcfg), 1, "Configure returns 1 (change $change) with server=false");
    ok(command_history_ok(undef, [qr{service nfs reload}]), "no nfs service reload when $change changed with server=false");
};


done_testing();
