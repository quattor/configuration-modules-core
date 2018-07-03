use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Quattor qw(sysmon);
use NCM::Component::gpfs;
use Test::Quattor::Object;
use Readonly;

my $obj = Test::Quattor::Object->new();

my $cfg = get_config_for_profile('sysmon');
my $cmp = NCM::Component::gpfs->new('gpfs', $obj);

ok(!defined($cmp->sysmon($cfg)), "sysmon returns undef on missing config file");

# 2 network sections
my $data = <<EOF;

[general]
use_dbus_lib = false

#
# Network configuration
#
[network]
family = AF_UNIX
port = /var/mmfs/mmsysmon/mmsysmonitor.socket

[recoverygroup]
monitorinterval = 180

[cloudgateway]
monitorinterval = 15

[network]
monitorinterval = 30
monitoroffset = 0
clockalign = false

EOF

my $newdata = <<EOF;
[cloudgateway]
monitorinterval=15

[general]
use_dbus_lib=false

[network]
clockalign=true
family=AF_UNIX
monitorinterval=60
monitoroffset=0
port=/var/mmfs/mmsysmon/mmsysmonitor.socket

[recoverygroup]
monitorinterval=180
EOF

my $cfn = '/var/mmfs/mmsysmon/mmsysmonitor.conf';
set_file_contents($cfn, $data);

command_history_reset();
ok($cmp->sysmon($cfg), "sysmon returns success");

my $fh = get_file($cfn);
diag "config file $fh";
is("$fh", $newdata, "configfile updated as expected");

ok(command_history_ok([
    '/usr/lpp/mmfs/bin/mmsysmoncontrol stop',
    '/usr/lpp/mmfs/bin/mmsysmoncontrol start',
    ]),
   "stop/start on change");

command_history_reset();
ok($cmp->sysmon($cfg), "sysmon returns success (no changes)");
ok(command_history_ok(undef, ['mm']), # no mm commands called
   "no stop/start no changes");

done_testing;
