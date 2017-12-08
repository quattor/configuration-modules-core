#${PMpre} NCM::Component::Ceph::Cluster${PMpost}

use 5.10.1;

use parent qw(CAF::Object NCM::Component::Ceph::Commands);
use NCM::Component::Ceph::Cfgfile;
use Readonly;
use JSON::XS;
use Data::Dumper;


sub _initialize
{
    my ($self, $cfgtree, $log, $prefix) = @_;

    $self->{log} = $log;
    $self->{cfgtree} = $cfgtree;
    $self->{prefix} = $prefix;
    $self->{config} = $cfgtree->getTree($self->{prefix});
    $self->{cluster} = $self->{config}->{cluster};
    $self->{cephusr};
    $self->{key_accept};
    
    $self->{init_hosts} = [];
    my $monitors = $self->{cluster}->{monitors};
    foreach my $host (sort(keys(%$monitors}))) {
        push (@{$self->{init_hosts}}, $monitors->{$host}->{fqdn});
    }

    return 1;
}

# Checks if cluster is configured on this node.
sub cluster_exists_check {
    my ($self) = @_;
    # Check If something is not configured or there is no existing cluster 
    my $ok= 0;
    foreach my $host (@{$self->{init_hosts}}) {
        if ($self->{key_accept}) {
            $self->ssh_known_keys($host, $key_accept, $cephusr);
        }
        if ($self->run_ceph_deploy_command([qw(gatherkeys), $host])) {
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
        if (!-f "$cephusr->{homeDir}/ceph.mon.keyring"){
            $self->run_ceph_deploy_command([@newcmd]);
        }
        $self->info("To create a new cluster, run this command");
        #my $moncr = $self->run_ceph_deploy_command([qw(mon create-initial)],'','',1);
        $self->print_cmds([$moncr]);
        return 0;
    } else {
        return 1;
    }
}


sub configure
{
    my ($self) = @_;
    
    return ;
};

1;
