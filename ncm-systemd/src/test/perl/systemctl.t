use strict;
use warnings;
use Test::More;
use Test::Quattor;
use NCM::Component::systemd;
use NCM::Component::Systemd::Systemctl qw(systemctl_show $SYSTEMCTL systemctl_list_units systemctl_list_unit_files);

use helper;

$CAF::Object::NoAction = 1;

=pod

=head1 DESCRIPTION

Test the C<Systemctl> module for systemd.

=head2 systemctl_show

Test systemctl_show

=cut

is($SYSTEMCTL, "/usr/bin/systemctl", "SYSTEMCTL exported");

my ($res, @names);

set_output("systemctl_show_runlevel6_target_el7");

# need a logger instance (could also use CAF::Object instance)
my $cmp = NCM::Component::systemd->new('systemd');
$res = systemctl_show($cmp, 'runlevel6.target');

is(scalar keys %$res, 63, "Found 63 keys");
is($res->{Id}, 'reboot.target', "Runlevel6 is reboot.target");

# test the split in array ref
my @isarray = qw(Names Requires Wants WantedBy Before After Conflicts);
foreach my $k (keys %$res) {
    my $r = ref($res->{$k});
    if (grep {$_ eq $k} @isarray) {
        is($r, 'ARRAY', "$k is converted to array reference");
    } else {
        ok(! $r,  "$k is not a reference");
    }
}
is_deeply($res->{Names}, ["runlevel6.target", "reboot.target"], "Runlevel6 names/aliases");

=pod 

=head2 systemctl_list

Test private systemctl_list

=cut

set_output("systemctl_list_unit_files_target");

$res = NCM::Component::Systemd::Systemctl::systemctl_list(
    $cmp, 
    "unit-files", 
    qr{^(?<fullname>(?<name>\S+)\.(?<type>\w+))\s+}, 
    "target");
is(scalar keys %$res, 54, "Found 54 unit-files for target");
is_deeply($res->{basic}, 
    {name => "basic", type => "target", fullname => "basic.target"} , 
    "Correct named groups assigned to basic.target");


=pod 

=head2 systemctl_list_units

Test systemctl_list_units

=cut

set_output("systemctl_list_units_target");
$res = systemctl_list_units($cmp, "target");

is(scalar keys %$res, 15, "Found 15 units for target");
is_deeply($res->{'multi-user'}, 
    {name => "multi-user", type => "target", fullname => "multi-user.target",
     loaded => 'loaded', active => 'active', running => 'active',   
    } , "Correct named groups assigned to unit multi-user.target");

set_output("systemctl_list_units_service");
$res = systemctl_list_units($cmp, "service");

is(scalar keys %$res, 52, "Found 52 units for service");
is_deeply($res->{'rc-local'}, 
    {name => "rc-local", type => "service", fullname => "rc-local.service",
     loaded => 'loaded', active => 'failed', running => 'failed',   
    } , "Correct named groups assigned to unit rc-local.service");

=pod 

=head2 systemctl_list_unit_files

Test systemctl_list_unit_files

=cut

set_output("systemctl_list_unit_files_target");
$res = systemctl_list_unit_files($cmp, "target");

is(scalar keys %$res, 54, "Found 54 unit-files for target");
is_deeply($res->{runlevel5}, 
    {name => "runlevel5", type => "target", fullname => "runlevel5.target", state => 'disabled'} , 
    "Correct named groups assigned to unit-file runlevel5.target");


set_output("systemctl_list_unit_files_service");
$res = systemctl_list_unit_files($cmp, "service");

is(scalar keys %$res, 154, "Found 154 unit-files for service");
is_deeply($res->{'serial-getty@'}, 
    {name => 'serial-getty@', type => 'service', fullname => 'serial-getty@.service', state => 'static'} , 
    'Correct named groups assigned to unit-file serial-getty@.service');

done_testing();
