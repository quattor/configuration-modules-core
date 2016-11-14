use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::systemd;
use NCM::Component::Systemd::Systemctl qw(systemctl_show $SYSTEMCTL
    systemctl_daemon_reload
    systemctl_list_units systemctl_list_unit_files
    systemctl_list_deps
    systemctl_command_units
    systemctl_is_enabled
    :properties
    );

use helper;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Systemctl> module for systemd.

=head2 exported constansts

Test exported constants

=cut

is($SYSTEMCTL, "/usr/bin/systemctl", "SYSTEMCTL exported");

my $all_props = [
    $PROPERTY_ACTIVESTATE, $PROPERTY_AFTER, $PROPERTY_BEFORE,
    $PROPERTY_CONFLICTS, $PROPERTY_ID, $PROPERTY_NAMES,
    $PROPERTY_REQUIREDBY, $PROPERTY_REQUIRES,
    $PROPERTY_TRIGGEREDBY, $PROPERTY_TRIGGERS,
    $PROPERTY_UNITFILESTATE, $PROPERTY_WANTEDBY,
    $PROPERTY_WANTS,
];
is_deeply($all_props,
          [qw(ActiveState After Before Conflicts Id Names RequiredBy Requires TriggeredBy Triggers UnitFileState WantedBy Wants)],
          "exported properties");

my @array_props = (
    $PROPERTY_AFTER, $PROPERTY_BEFORE, $PROPERTY_CONFLICTS,
    $PROPERTY_NAMES, $PROPERTY_REQUIREDBY, $PROPERTY_REQUIRES,
    $PROPERTY_TRIGGEREDBY, $PROPERTY_TRIGGERS,
    $PROPERTY_WANTEDBY, $PROPERTY_WANTS,
);

=pod

=head2 systemctl_show

Test systemctl_show

=cut

my ($res, @names);

set_output("systemctl_show_runlevel6_target_el7");

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');
$res = systemctl_show($cmp, 'runlevel6.target');

is(scalar keys %$res, 63, "Found 63 keys");
is($res->{Id}, 'reboot.target', "Runlevel6 is reboot.target");

# test the split in array ref
foreach my $k (keys %$res) {
    my $r = ref($res->{$k});
    if (grep {$_ eq $k} @array_props) {
        is($r, 'ARRAY', "$k is converted to array reference");
    } else {
        ok(! $r,  "$k is not a reference");
    }
}
is_deeply($res->{Names}, ["runlevel6.target", "reboot.target"], "Runlevel6 names/aliases");


=head2 systemctl_daemon_reload

Test systemctl_daemon_reload

=cut

$cmp->{ERROR}= 0;
$cmp->{WARN}= 0;

# test normal: exitcode 0, no output
set_output("systemctl_daemon_reload");
ok(systemctl_daemon_reload($cmp), "daemon reload ok");
is($cmp->{ERROR}, 0, 'No error logged during succesful daemon reload');
is($cmp->{WARN}, 0, 'No warn logged during succesful daemon reload');

# test exitcode 0, with output
set_output("systemctl_daemon_reload_output");
ok(systemctl_daemon_reload($cmp), "daemon reload ok with output");
is($cmp->{ERROR}, 0, 'No error logged during succesful daemon reload with output');
is($cmp->{WARN}, 1, 'warn logged during succesful daemon reload with output');

# test exit 1
$cmp->{WARN}= 0;
set_output("systemctl_daemon_reload_fail");
ok(! defined(systemctl_daemon_reload($cmp)), "daemon reload returns undef on failure");
is($cmp->{ERROR}, 1, 'Error logged during failed daemon reload');
is($cmp->{WARN}, 0, 'No warn logged during failed daemon reload');

=pod

=head2 systemctl_list

Test private systemctl_list

=cut

set_output("systemctl_list_unit_files_target");

$res = NCM::Component::Systemd::Systemctl::systemctl_list(
    $cmp,
    "unit-files",
    qr{^(?<name>(?<shortname>\S+)\.(?<type>\w+))\s+},
    "target");
is(scalar keys %$res, 54, "Found 54 unit-files for target");
is_deeply($res->{'basic.target'},
    {shortname => "basic", type => "target", name => "basic.target"} ,
    "Correct named groups assigned to basic.target");


=pod

=head2 systemctl_list_units

Test systemctl_list_units

=cut

set_output("systemctl_list_units_target");
$res = systemctl_list_units($cmp, "target");

is(scalar keys %$res, 15, "Found 15 units for target");
is_deeply($res->{'multi-user.target'},
    {shortname => "multi-user", type => "target", name => "multi-user.target",
     loaded => 'loaded', active => 'active', running => 'active',
    } , "Correct named groups assigned to unit multi-user.target");

set_output("systemctl_list_units_service");
$res = systemctl_list_units($cmp, "service");

is(scalar keys %$res, 52, "Found 52 units for service");
is_deeply($res->{'rc-local.service'},
    {shortname => "rc-local", type => "service", name => "rc-local.service",
     loaded => 'loaded', active => 'failed', running => 'failed',
    } , "Correct named groups assigned to unit rc-local.service");

=pod

=head2 systemctl_list_unit_files

Test systemctl_list_unit_files

=cut

set_output("systemctl_list_unit_files_target");
$res = systemctl_list_unit_files($cmp, "target");

is(scalar keys %$res, 54, "Found 54 unit-files for target");
is_deeply($res->{'runlevel5.target'},
    {shortname => "runlevel5", type => "target", name => "runlevel5.target",
     state => 'disabled'},
    "Correct named groups assigned to unit-file runlevel5.target");


set_output("systemctl_list_unit_files_service");
$res = systemctl_list_unit_files($cmp, "service");

is(scalar keys %$res, 154, "Found 154 unit-files for service");
is_deeply($res->{'serial-getty@.service'},
    {shortname => 'serial-getty@', type => 'service', name => 'serial-getty@.service',
     state => 'static'},
    'Correct named groups assigned to unit-file serial-getty@.service');

=pod

=item systemctl_list_deps

Test the systemctl_list_deps method

=cut

my $unitname;

set_output("systemctl_list_dependencies_sshd_service");
$unitname = "sshd.service";
$res = systemctl_list_deps($cmp, $unitname);
ok($res->{$unitname}, "Unit $unitname itself is in the list of dependencies for unit $unitname");
is(scalar keys %$res, 61, "Found 61 dependecies for unit $unitname");

# some common ones
my @deps = qw(-.mount basic.target local-fs.target);
for my $depname (@deps) {
    ok($res->{$depname}, "Unit $depname is in the list of dependencies for unit $unitname");
}

set_output("systemctl_list_dependencies_sshd_service_reverse");
$res = systemctl_list_deps($cmp, $unitname, 1);
ok($res->{$unitname}, "Unit $unitname itself is in the list of reverse dependencies");
is(scalar keys %$res, 3, "Found 3 reverse dependecies for unit $unitname");

set_output("systemctl_list_dependencies_default_target");
$unitname = "default.target";
$res = systemctl_list_deps($cmp, $unitname);
ok($res->{$unitname}, "Unit $unitname itself is in the list of dependencies for unit $unitname");
is(scalar keys %$res, 95, "Found 95 dependecies for unit $unitname");

set_output("systemctl_list_dependencies_default_target_reverse");
$res = systemctl_list_deps($cmp, $unitname, 1);
ok($res->{$unitname}, "Unit $unitname itself is in the list of reverse dependencies");
is(scalar keys %$res, 2, "Found 2 reverse dependecies for unit $unitname");

set_output("systemctl_list_dependencies_multiuser_target");
$unitname = "multi-user.target";
$res = systemctl_list_deps($cmp, $unitname);
ok($res->{$unitname}, "Unit $unitname itself is in the list of dependencies for unit $unitname");
is(scalar keys %$res, 95, "Found 95 dependecies for unit $unitname");

set_output("systemctl_list_dependencies_multiuser_target_reverse");
$res = systemctl_list_deps($cmp, $unitname, 1);
ok($res->{$unitname}, "Unit $unitname itself is in the list of reverse dependencies");
is(scalar keys %$res, 2, "Found 2 reverse dependecies for unit $unitname");


=pod

=head2 systemctl_command_units

Test systemctl_command_units

=cut

my $cmd = "$SYSTEMCTL fake-command -- unit1.type unit2.type";
my $out = "testok";
set_command_status($cmd, 0);
set_desired_output($cmd, $out);

$cmp->{ERROR}= 0;
my ($ec, $output) = systemctl_command_units($cmp, 'fake-command', 'unit1.type', 'unit2.type');

is($cmp->{ERROR}, 0, "No errors logged during systemctl_command_units $cmd");
is($ec, 0, "systemctl_command_units finished with exitcode $ec");
is($output, $out, "systemctl_command_units finished with output $out");

$cmd .= " unit3.type";
$out = "FAIL";
set_command_status($cmd, 5);
set_desired_output($cmd, $out);

($ec, $output) = systemctl_command_units($cmp, 'fake-command', 'unit1.type', 'unit2.type', 'unit3.type');

is($cmp->{ERROR}, 1, "1 error logged during systemctl_command_units $cmd");
is($ec, 5, "systemctl_command_units finished with exitcode $ec");
is($output, $out, "systemctl_command_units finished with output $out");

=pod

=head2 systemctl_is_enabled

Test systemctl_is_enabled

=cut

$cmd = "$SYSTEMCTL is-enabled -- unit1.type";
$out = "isenabled";
my $err = "some err data";
set_command_status($cmd, 0);
# with newline
set_desired_output($cmd, "$out\n");
set_desired_err($cmd, $err);

$cmp->{ERROR} = 0;
is(systemctl_is_enabled($cmp, 'unit1.type'), $out,
   "is_enabled returns (chomped) stdout, no stderr");

is($cmp->{ERROR}, 0, "No errors logged during systemctl_is_enabled $cmd");

$cmd = "$SYSTEMCTL is-enabled -- unit3.type";
# empty stdout is actual error condition
$out = "";
set_command_status($cmd, 5);
set_desired_output($cmd, "$out\n");

ok(! defined(systemctl_is_enabled($cmp, 'unit3.type')),
   "systemctl_is_enabled returns undef on failure");

is($cmp->{ERROR}, 1, "1 error logged during systemctl_is_enabled $cmd");

=pod

=back

=cut

done_testing();
