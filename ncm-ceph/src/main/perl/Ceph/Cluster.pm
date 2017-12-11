#${PMpre} NCM::Component::Ceph::Cluster${PMpost}

use 5.10.1;

use parent qw(CAF::Object NCM::Component::Ceph::Commands NCM::Component::Ceph::MONs NCM::Component::Ceph::MDSs);
use NCM::Component::Ceph::Cfgfile;
use Readonly;
use JSON::XS;
use Data::Dumper;

Readonly my $CEPH_USER_ELEMENT => '/software/components/accounts/users/ceph';
Readonly my $CEPH_GROUP_ELEMENT => '/software/components/accounts/groups/ceph';
Readonly my $CEPH_DEPLOY_CFGFILE => '/home/ceph/ceph.conf';

sub _initialize
{
    my ($self, $cfgtree, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{cfgtree} = $cfgtree;
    $self->{prefix} = $prefix;
    $self->{config} = $cfgtree->getTree($self->{prefix});
    $self->{cluster} = $self->{config}->{cluster};

    my $group = $cfgtree->getElement($CEPH_GROUP_ELEMENT)->getTree();
    $self->{cephusr} = $cfgtree->getElement($CEPH_USER_ELEMENT)->getTree();
    $self->{cephusr}->{gid} = $group->{gid};

    $self->{key_accept} = $self->{cluster}->{key_accept};
    $self->{ssh_multiplex} = $self->{cluster}->{ssh_multiplex};

    my $netw = $cfgtree->getElement('/system/network')->getTree();
    $self->{hostname} = $netw->{hostname};

    $self->{init_hosts} = [];
    my $monitors = $self->{cluster}->{monitors};
    foreach my $host (sort(keys(%$monitors))) {
        push (@{$self->{init_hosts}}, $monitors->{$host}->{fqdn});
    }

    return 1;
}

# Checks if cluster is configured on this node.
sub cluster_exists 
{
    my ($self) = @_;
    # Check If something is not configured or there is no existing cluster 
    my $ok= 0;
    foreach my $host (@{$self->{init_hosts}}) {
        if ($self->{key_accept}) {
            $self->ssh_known_keys($host, $self->{key_accept}, $self->{cephusr});
        }
        if ($self->run_ceph_deploy_command([qw(gatherkeys), $host], 'gather ceph keyrings from monitors')) {
            $ok = 1;
            last;
        }
    }
    if (!$ok) {
        # Manual commands for new cluster  
        # Run command with ceph-deploy for automation, 
        # but take care of race conditions

        my @newcmd = qw(new);
        foreach my $host (@{$self->{init_hosts}}) {
            push (@newcmd, $host);
        }
        if (!-f "$self->{cephusr}->{homeDir}/ceph.mon.keyring"){
            $self->run_ceph_deploy_command([@newcmd], 'create new ceph cluster files');
        }
        $self->info("To create a new cluster, run this command");
        my $moncr = $self->run_ceph_deploy_command([qw(mon create-initial)],'create initial monitors', printonly => 1);
        return 0;
    } else {
        return 1;
    }
}

# Fail if cluster not ready and no deploy hosts
sub cluster_ready {
    my ($self) = @_;

    if (!$self->run_ceph_command([qw(status)])) {
            my @admin = ('admin', $self->{hostname});
            $self->run_ceph_deploy_command(\@admin);
            if (!$self->run_ceph_command([qw(status)])) {
                # This should not happen
                $self->error("Cannot connect to ceph cluster!");
                return 0;
            } else {
                $self->debug(1,"Node ready to receive ceph-commands");
            }
    }
    return 1;
}

sub write_init_cfg
{
    my ($self) = @_;
    my $cfgfile = NCM::Component::Ceph::Cfgfile->new(
        $self->{cfgtree}, $self, "$self->{prefix}/cluster/initcfg", $CEPH_DEPLOY_CFGFILE);
    if (!$cfgfile->configure()) {
         $self->error('Could not write cfgfile for ceph-deploy, aborting deployment');
         return;
    }

}

sub prepare_cluster
{
    my ($self) = @_;

    my $exists = $self->cluster_exists();
    $self->write_init_cfg() or return;
    return if !$exists;

    $self->cluster_ready() or return;
    
    return 1;
};

sub test_host_connections
{
    my ($self, $map) = @_;
    foreach my $host (keys %{$map->get_quattor_map}){
        if (! $self->test_host_connection($map->get_fqdn($host), $self->{key_accept}, $self->{cephusr})){
            $self->error("Can't reach ", $map->get_fqdn($host), " for configuration");
            return;
        }
    }
}

# get running config and see what needs to be deployed
sub make_tasks
{
    my ($self) = @_;
    my $map = NCM::Component::Ceph::ClusterMap->new($self);
    $map->map_existing() or return;
    $map->map_quattor() or return;
    $self->test_host_connections($map) or return;
    return $map->get_deploy_map();
}



sub configure
{
    my ($self) = @_;
    $self->prepare_cluster() or return

    my $map = $self->make_tasks() or return;

    $self->deploy_daemons($map) or return;
};

1;
