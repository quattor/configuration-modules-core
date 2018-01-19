#${PMpre} NCM::Component::Ceph::Cluster${PMpost}

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
    my ($self, $config, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{config} = $config;
    $self->{prefix} = $prefix;
    $self->{tree} = $config->getTree($self->{prefix});
    $self->{cluster} = $self->{tree}->{cluster};

    my $group = $config->getTree($CEPH_GROUP_ELEMENT);
    $self->{cephusr} = $config->getTree($CEPH_USER_ELEMENT);
    $self->{cephusr}->{gid} = $group->{gid};

    $self->{key_accept} = $self->{cluster}->{key_accept};
    $self->{ssh_multiplex} = $self->{cluster}->{ssh_multiplex};

    my $netw = $config->getTree('/system/network');
    $self->{hostname} = $netw->{hostname};

    my $monitors = $self->{cluster}->{monitors};
    $self->{init_hosts} = [map {$monitors->{$_}->{fqdn}} sort keys %$monitors];

    return 1;
}

# Checks if cluster is configured on this node.
sub cluster_exists
{
    my ($self) = @_;
    # Check if something is not configured or there is no existing cluster
    my $ok = 0;
    foreach my $host (@{$self->{init_hosts}}) {
        if ($self->{key_accept}) {
            $self->ssh_known_keys($host, $self->{key_accept}, $self->{cephusr});
        }
        if ($self->run_ceph_deploy_command([qw(gatherkeys), $host], 'gather ceph keyrings from monitors')) {
            $ok = 1;
            last;
        }
    }
    if ($ok) {
        $self->debug(1, 'Found existing cluster');
        return 1;
    } else {
        # Manual commands for new cluster
        # Run command with ceph-deploy for automation,
        # but take care of race conditions

        my @newcmd = qw(new);
        push (@newcmd, @{$self->{init_hosts}});
        if (!$self->file_exists("$self->{cephusr}->{homeDir}/ceph.mon.keyring", test => 1)){
            $self->run_ceph_deploy_command([@newcmd], 'create new ceph cluster files');
        }
        $self->info("To create a new cluster, run following command");
        $self->run_ceph_deploy_command([qw(mon create-initial)], 'create initial monitors', printonly => 1, overwritecfg => 1);
        return;
    }
}

# Fail if cluster not ready and no deploy hosts
sub cluster_ready
{
    my ($self) = @_;

    if (!$self->run_ceph_command([qw(status)], 'get cluster status')) {
        my @admin = ('admin', $self->{hostname});
        $self->run_ceph_deploy_command(\@admin);
        if (!$self->run_ceph_command([qw(status)], 'get cluster status')) {
            # This should not happen
            $self->error("Cannot connect to ceph cluster!");
            return;
        }
    }
    $self->debug(1, "Node ready to receive ceph-commands");
    return 1;
}

sub write_init_cfg
{
    my ($self) = @_;
    my $cfgfile = NCM::Component::Ceph::Cfgfile->new(
        $self->{config}, $self, "$self->{prefix}/cluster/initcfg", $CEPH_DEPLOY_CFGFILE);
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
    foreach my $host (sort keys %{$map->get_quattor_map}){
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
    my $success = $self->run_ceph_deploy_command([qw(config pull), $host], "get config from $host", overwritecfg => 1);
    $self->run_ceph_deploy_command([qw(admin), $host], "set admin $host"); # mon,mgr,mds as admin
    return $success || $self->write_init_cfg();

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
    return 1;
}

sub configure
{
    my ($self) = @_;
    $self->prepare_cluster() or return;

    my $map = $self->make_tasks() or return;

    $self->deploy($map) or return;
}

1;
