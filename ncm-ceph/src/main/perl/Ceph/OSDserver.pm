#${PMpre} NCM::Component::Ceph::OSDserver${PMpost}

use 5.10.1;

use parent qw(CAF::Object NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use EDG::WP4::CCM::Path qw(escape unescape);
use Readonly;
use JSON::XS;
use Data::Dumper;

Readonly my @BOOTSTRAP_OSD_KEYRING_CMD => qw(stat /var/lib/ceph/bootstrap-osd/ceph.keyring);
Readonly my @GET_CEPH_PVS_CMD => (qw(pvs -o), 'pv_name,lv_tags', qw(--no-headings --reportformat json));

sub _initialize
{
    my ($self, $cfgtree, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{cfgtree} = $cfgtree;
    $self->{prefix} = $prefix;
    $self->{config} = $cfgtree->getTree($self->{prefix});
    $self->{ok_failures} = $self->{config}->{max_add_osd_failures};

    $self->{osds} = $self->{config}->{daemons}->{osds};
    return 1;
}

sub is_node_healthy
{
    my ($self) = @_;
    # Check bootstrab-osd keyring
    # stat /var/lib/ceph/bootstrap-osd/ceph.keyring
    my $ok = $self->run_command([@BOOTSTRAP_OSD_KEYRING_CMD], "stat bootstrap-osd keyring", test => 1);
    # Checks can be added
    return $ok;

}

sub run_pvs
{
    my ($self, $osds) = @_;
    my ($ok, $jstr) = $self->run_command([@GET_CEPH_PVS_CMD], "get ceph pvs");
    return if (!$ok);
    my $report = decode_json($jstr);
    $self->debug(4, Dumper($report));
    if (!defined($report->{report}[0]->{pv})) {
        $self->error('Could not procces pvs json output');
        return;
    }
    my $pvs = $report->{report}[0]->{pv};
    foreach my $pv (@$pvs) {
        if ($pv->{lv_tags} =~ m/ceph.osd_id=(\d+),/) {
            my $id = $1;
            $self->verbose("Found existing osd pv for device $pv->{pv_name}");
            my $device = $pv->{pv_name};
            $device =~ s/^\/dev\///;
            $device = escape($device);
            $self->debug(3,"Adding escaped device $device");
            $osds->{$device} = { id => $id }
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
    foreach my $osd (sort keys(%{$self->{osds}})) {
        if ($deployed->{$osd}) {
            $self->{osds}->{$osd}->{deployed} = 1;
            $self->debug(1, "$osd already deployed");
            delete $deployed->{$osd};
        } else {
            $self->debug(1, "$osd marked for deployment");
            $self->{osds}->{$osd}->{deployed} = 0;
        }
    }
    if (%$deployed) {
        $self->error('Found deployed osds that are not in config: ', sort keys(%$deployed));
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
    my $succes = $self->run_command([qw(ceph-volume lvm create), "--$attrs->{storetype}", "--data", $devpath], "deploy osd $devpath");
    if (!$succes) {
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
    $self->info('Start deploying OSD Daemons');
    foreach my $osd (sort keys(%{$self->{osds}})) {
        if (!$self->{osds}->{$osd}->{deployed}) {
            $self->info('Deploying osd', $osd);
            $self->deploy_osd($osd, $self->{osds}->{$osd}) or return;
        }
    }
    $self->verbose('OSD Daemons deployed');
}

sub do_post
{
    my ($self) = @_;
    # Nothing yet, possibly osd crush classes
    return 1;
}

sub configure
{
    my ($self) = @_;
    
#    my $cfgfile = NCM::Component::Ceph::Cfgfile->new($self->{cfgtree}, $self, $self->{prefix});
#    if (!$cfgfile->configure()) {
#        $self->error('Could not write cfgfile, aborting deployment');
#        return;
#    }

    $self->is_node_healthy() or return;
    $self->prepare_osds() or return;
    $self->deploy() or return;
    $self->do_post() or  return;

    return 1;
}

1;
