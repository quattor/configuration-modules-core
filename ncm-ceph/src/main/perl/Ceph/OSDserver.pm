#${PMpre} NCM::Component::Ceph::OSDserver${PMpost}

use parent qw(CAF::Object NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use EDG::WP4::CCM::Path qw(escape unescape);
use Readonly;
use JSON::XS;
use Data::Dumper;

Readonly my $BOOTSTRAP_OSD_KEYRING => '/var/lib/ceph/bootstrap-osd/ceph.keyring';
Readonly my $BOOTSTRAP_OSD_KEYRING_SL => '/etc/ceph/ceph.client.bootstrap-osd.keyring';
Readonly my @BOOTSTRAP_OSD_CEPH_HEALTH => qw(status --id bootstrap-osd);
Readonly my @BOOTSTRAP_OSD_DUMP => qw(osd dump --id bootstrap-osd);
Readonly my @GET_CEPH_PVS_CMD => (qw(pvs -o), 'pv_name,lv_tags', qw(--no-headings --reportformat json));

sub _initialize
{
    my ($self, $config, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{config} = $config;
    $self->{prefix} = $prefix;
    $self->{tree} = $config->getTree($self->{prefix});
    $self->{ok_failures} = $self->{tree}->{daemons}->{max_add_osd_failures};

    $self->{osds} = $self->{tree}->{daemons}->{osds};
    return 1;
}

sub is_node_healthy
{
    my ($self) = @_;
    # Check bootstrap-osd keyring
    $self->debug(3, 'Checking if necessary files exists and we can connect to the cluster');
    $self->file_exists($BOOTSTRAP_OSD_KEYRING) or return;
    $self->file_exists($BOOTSTRAP_OSD_KEYRING_SL) or return;
    # Checks can be added
    if (!$self->run_ceph_command([@BOOTSTRAP_OSD_CEPH_HEALTH], "get cluster state", timeout => 20)) {
        $self->error('Cluster not reachable or correctly configured');
        return;
    }
    $self->debug(3, 'We can succesfully connect to the cluster');
    return 1;

}

# Run pvs command to find the existing deployed osds with ceph-volume.
# Needs a hash and will add the parsed osds of pvs to the hash
sub run_pvs
{
    my ($self, $osds) = @_;
    my ($ok, $jstr) = $self->run_command([@GET_CEPH_PVS_CMD], "get ceph pvs", nostderr => 1);
    return if (!$ok);
    my $report = decode_json($jstr);
    $self->debug(4, Dumper($report));
    if (!defined($report->{report}[0]->{pv})) {
        $self->error('Could not process pvs json output');
        return;
    }
    my $pvs = $report->{report}[0]->{pv};
    foreach my $pv (@$pvs) {
        if ($pv->{lv_tags} =~ m/ceph.osd_fsid=(\S+),ceph.osd_id=(\d+)/) {
            my ($uuid, $id) = ($1, $2);
            $self->verbose("Found existing osd pv for device $pv->{pv_name}");
            my $device = $pv->{pv_name};
            $device =~ s/^\/dev\///;
            $device = escape($device);
            $self->debug(3," Adding escaped device $device");
            $osds->{$device} = { id => $id, uuid => $uuid }
        }
    }
    return 1;
}

sub get_deployed_osds
{
    my ($self) = @_;
    my $osds = {};
    $self->verbose('Fetching deployed osds');
    # Get pvs output
    $self->run_pvs($osds) or return;

    # osds = { sdx => {osd_id => id }}
    return $osds;
}

sub prepare_osds
{
    my ($self) = @_;
    $self->verbose('Start preparing OSDs');
    my $deployed = $self->get_deployed_osds() or return;
    foreach my $osd (sort keys %{$self->{osds}}) {
        if ($deployed->{$osd}) {
            $self->{osds}->{$osd}->{deployed} = 1;
            $self->debug(2, "$osd already deployed");
            delete $deployed->{$osd};
        } else {
            $self->debug(2, "$osd marked for deployment");
            $self->{osds}->{$osd}->{deployed} = 0;
        }
    }
    if (%$deployed) {
        $self->error('Found deployed osds that are not in config: ', join(',', sort keys(%$deployed)));
        return;
    }
    $self->verbose('Preparing OSDs finished');

    return 1
}

sub deploy_osd
{
    my ($self, $name, $attrs) = @_;

    if ($attrs->{storetype} ne 'bluestore'){
        $self->error('Only bluestore is supported at the moment');
        return;
    }
    # ceph-volume lvm create --bluestore --data /dev/sdk
    my $devpath = "/dev/" . unescape($name);
    my $success = $self->run_command([qw(ceph-volume lvm create), "--$attrs->{storetype}", "--data", $devpath],
        "deploy osd $devpath");
    if (!$success) {
        if ($self->{ok_failures}){
            $self->{ok_failures}--;
            $self->warn("Ignored osd deploy failure for $devpath, ",
                "$self->{ok_failures} more failures accepted");
            return 1;
        } else {
            return;
        }
    }
    $self->debug(1, "Deployed osd $name");
    return 1;
}

sub deploy
{
    my ($self) = @_;
    $self->verbose('Start deploying OSD Daemons if needed');
    foreach my $osd (sort keys %{$self->{osds}}) {
        if (!$self->{osds}->{$osd}->{deployed}) {
            $self->info("Deploying osd $osd");
            $self->deploy_osd($osd, $self->{osds}->{$osd}) or return;
        }
    }
    $self->verbose('OSD Daemons deployed');
    return 1;
}

# make a osd id -> uuid map from osd dump
sub osd_map
{
    my ($self) = @_;
    my ($ec, $jstr) = $self->run_ceph_command([@BOOTSTRAP_OSD_DUMP], 'get osd dump', nostderr => 1) or return;
    my $osdinfo = decode_json($jstr);
    my %osds = map { $_->{osd} => $_->{uuid} } @{$osdinfo->{osds}};
    $self->debug(3, "osd dump id - uuid mapping: ", Dumper(\%osds));
    if (!%osds) {
        $self->error('Could not map osds from osd dump');
        return;
    }
    return \%osds;
}

# get the osd name from device name. The id is checked trough the ceph osd map
sub get_osd
{
    my ($self, $device, $deployed, $osdmap) = @_;
    my $id = $deployed->{$device}->{id};
    my $uuid = $deployed->{$device}->{uuid};

    if (!defined($id) || !defined($uuid)){
        $self->error("No deployed osd found for device $device.");
        return;
    }
    if (!defined($osdmap->{$id})) {
        $self->error("Id $id for device $device not found in ceph map.");
        return;
    }
    if ($uuid eq $osdmap->{$id}) {
        $self->debug(4, "Mapping between device $device and id $id ok");
    } else {
        $self->error("Wrongly mapped device $device to id $id. uuid on disk: $uuid, uuid in osd map: $osdmap->{$id}");
        return;
    }
    return "osd.$id";
}

# updates the class of an osd if needed
sub overwrite_class
{
    my ($self, $osd, $class) = @_;
    my $success = $self->run_ceph_command([qw(osd crush set-device-class), $class, $osd], "set class of $osd");
    if ($success) {
        $self->verbose("Class $class for device $osd (already) set");
    } else {
        $self->info("Device $osd will have class changed to $class");
        $self->run_ceph_command([qw(osd crush rm-device-class), $osd], "remove class of $osd");
        $self->run_ceph_command([qw(osd crush set-device-class), $class, $osd], "set class of $osd") or return;
    }
    return 1;
}

# check if there are osds that need class overwrites
sub check_classes
{
    my ($self) = @_;
    # updated deployed osd list
    $self->debug(2, 'check for defined osd class overwrites');
    my $deployed = $self->get_deployed_osds() or return;
    my $osdmap = $self->osd_map();
    foreach my $device (sort keys %{$self->{osds}}) {
        my $osd = $self->{osds}->{$device};
        if ($osd->{class}){
            $self->verbose("OSD $device has class overwrite");
            my $osdname = $self->get_osd($device, $deployed, $osdmap) or return;
            $self->overwrite_class($osdname, $osd->{class}) or return;
        }
    }
    return 1;
}

sub do_post
{
    my ($self) = @_;
    $self->check_classes() or return;
    return 1;
}

sub configure
{
    my ($self) = @_;
    $self->debug(2, 'Configuring osd server');
    $self->is_node_healthy() or return;
    $self->prepare_osds() or return;
    $self->deploy() or return;
    $self->do_post() or  return;

    return 1;
}

1;
