#${PMpre} NCM::Component::Ceph::Cluster${PMpost}

use 5.10.1;

use parent qw(CAF::Object NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use NCM::Component::Ceph::ClusterMap;
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
        $self->run_ceph_deploy_command([qw(mon create-initial)],'create initial monitors', printonly => 1, rwritecfg => 1);
        return 0;
    } else {
        $self->debug(1, 'Found existing cluster');
        return 1;
    }
}

# Fail if cluster not ready and no deploy hosts
sub cluster_ready {
    my ($self) = @_;

    if (!$self->run_ceph_command([qw(status)], 'get cluster status' )) {
            my @admin = ('admin', $self->{hostname});
            $self->run_ceph_deploy_command(\@admin);
            if (!$self->run_ceph_command([qw(status)], 'get cluster status')) {
                # This should not happen
                $self->error("Cannot connect to ceph cluster!");
                return 0;
            }
    }
    $self->debug(1, "Node ready to receive ceph-commands");
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
    $self->debug(1, "Initial config file has been set");
    return 1;

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
    $self->debug(1, 'All nodes reachable');
    return 1;
}

# get running config and see what needs to be deployed
sub make_tasks
{
    my ($self) = @_;
    $self->verbose('Comparing daemons to determine what needs to be deployed');
    my $map = NCM::Component::Ceph::ClusterMap->new($self);
    $map->map_existing() or return;
    $map->map_quattor() or return;
    $self->test_host_connections($map) or return;
    return $map->get_deploy_map();
}

# Deploys a single daemon
sub deploy_daemon 
{
    my ($self, $cmd, $name, $type) = @_;
    push (@$cmd, $name);
    $self->info('Deploying daemon: ', join(' ', @$cmd));
    return $self->run_ceph_deploy_command($cmd, "deploy $type $name" );
}

sub deploy_daemons {
    my ($self, $host, $hostname) = @_;
    if ($host->{mon}) {
        $self->deploy_daemon([qw(mon create)], $host->{mon}->{fqdn}, 'mon') or return;
    }
    if ($host->{mgr}) {
        $self->deploy_daemon([qw(mgr create)], "$host->{mgr}->{fqdn}:$hostname", 'mgr') or return;
    }
    if ($host->{mds}) {
        $self->deploy_daemon([qw(mds create)], "$host->{mds}->{fqdn}:$hostname", 'mds') or return;
    }
    return 1;
}

sub pull_cfg
{
    my ($self, $host) = @_;
    my $succes = $self->run_ceph_deploy_command([qw(config pull), $host], "get config from $host", rwritecfg => 1);
    return $succes || $self->write_init_cfg();
    
}
sub deploy
{
    my ($self, $map) = @_;

    $self->debug(5, "deploy hash:", Dumper($map));
    $self->verbose("Running ceph-deploy commands. This can take some time when adding new daemons.");
    foreach my $hostname (sort keys(%{$map})) {
        $self->pull_cfg($map->{$hostname}->{fqdn}) or return;
        $self->deploy_daemons($map->{$hostname}, $hostname) or return;
    }
    return 1
}

sub configure
{
    my ($self) = @_;
    $self->prepare_cluster() or return;

    my $map = $self->make_tasks() or return;

    $self->deploy($map) or return;
};

1;
