use strict;
use warnings;

BEGIN {
    *CORE::GLOBAL::sleep = sub {};
}

use Test::More;
use Test::Quattor qw(rename);
use Test::Quattor::Filetools qw(readfile);
use NCM::Component::network;

use Readonly;

# File must exist
set_file_contents("/etc/sysconfig/network", '');
# must also exist (to flag the interface down)
set_file_contents("/etc/sysconfig/network-scripts/ifcfg-em1", '');


my $cfg = get_config_for_profile('rename');
my $cmp = NCM::Component::network->new('network');
$cmp->directory('/sys/devices/virtual/net/br100');
$cmp->directory('/sys/class/net');
$cmp->symlink('/some/path', '/sys/class/net/em1');

set_desired_output('ip addr show', readfile('src/test/resources/output/ipaddrshowrename'));

my $map = $cmp->make_dev2mac();
diag "dev2mac map ", explain $map;
is_deeply($map, {em1 => 'aa:bb:cc:dd:ee:ff'}, "dev2mac map");

# hw cards nic is ok, we only need hwaddr entry
my $rename = $cmp->make_rename_map($map, $cfg->getTree("/hardware/cards/nic"));
diag "rename map ", explain $rename;
is_deeply($rename, {em1 => 'eth0'}, "rename map");

is($cmp->Configure($cfg), 1, "Component runs correctly with a test profile");

ok(command_history_ok([
    'ip addr show',
    'ifdown em1',
    'ifdown eth0',
    'service network stop',
    'ip link set em1 down',
    'ip link set em1 name eth0',
    'service network start',
]), "network stop/start called with device renaming");


done_testing();
