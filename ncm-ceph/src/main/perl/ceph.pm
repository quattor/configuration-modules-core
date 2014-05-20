# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


# This component needs a 'ceph' user. 
# The user should be able to run these commands with sudo without password:
# /usr/bin/ceph-deploy
# /usr/bin/python -c import sys;exec(eval(sys.stdin.readline()))
# /usr/bin/python -u -c import sys;exec(eval(sys.stdin.readline()))
# /bin/mkdir
#

package NCM::Component::${project.artifactId};

use 5.10.1;
use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';
use base qw(NCM::Component NCM::Component::Ceph::commands NCM::Component::Ceph::crushmap
    NCM::Component::Ceph::daemon NCM::Component::Ceph::config );

use LC::Exception;
use LC::Find;
use LC::File qw(makedir);

use File::Path qw(make_path);
use File::Copy qw(copy move);
use Git::Repository;
use JSON::XS;
use Text::Glob qw(match_glob);
our $EC=LC::Exception::Context->new->will_store_all;

# Initiates gitrepo
sub init_git {
    my ($self, $qdir) = @_;
    if (!-d "$qdir/.git"){
        Git::Repository->run( init => $qdir );
    } # Access with my $gitr = Git::Repository->new( work_tree => $qdir );
}
 
#Make sure  a temporary directory is created for push and pulls
sub init_qdepl {
    my ($self, $config, $cephusr) = @_;
    my $qdir = $cephusr->{homeDir} . '/ncm-ceph/';
    my $crushdir = $qdir . 'crushmap/' ;
    make_path($qdir, $crushdir, {owner=>$cephusr->{uid}, group=>$cephusr->{gid}});
    $self->init_git($qdir);
    return $qdir; 
}
   
#Checks if cluster is configured on this node.
sub cluster_exists_check {
    my ($self, $cluster, $cephusr, $clname) = @_;
    # Check If something is not configured or there is no existing cluster 
    my $hosts = $cluster->{config}->{mon_host};
    my $ok= 0;
    my $okhost;
    foreach my $host (@{$hosts}) {
        if ($self->run_ceph_deploy_command([qw(gatherkeys), $host])) {
            $ok = 1;
            $okhost = $host;
            last;
        }    
    }
    if (!$ok) {
        # Manual commands for new cluster  
        # Run command with ceph-deploy for automation, 
        # but take care of race conditions
        
        my @newcmd = qw(new);
        foreach my $host (@{$hosts}) {
            push (@newcmd, $host);
        }
        if (!-f "$cephusr->{homeDir}/$clname.mon.keyring"){
            $self->run_ceph_deploy_command([@newcmd]);
        }
        my @moncr = qw(/usr/bin/ceph-deploy mon create-initial);
        $self->print_cmds([[@moncr]]);
        return 0;
    } else {
        return 1;
    }
}

#Fail if cluster not ready and no deploy hosts
sub cluster_ready_check {
    my ($self, $cluster, $is_deploy, $hostname) = @_;
   
    if (!$self->run_ceph_command([qw(status)])) {
        if ($is_deploy) {
            my @admin = ('admin', $hostname);
            $self->run_ceph_deploy_command(\@admin);
            if (!$self->run_ceph_command([qw(status)])) {
                $self->error("Cannot connect to ceph cluster!"); #This should not happen
                return 0;
            } else {
                $self->debug(1,"Node ready to receive ceph-commands");
            }
        } else {
            $self->error("Cluster not configured and no ceph deploy host.." . 
                "Run on a deploy host!"); 
            return 0;
        }
    }
    return 1;
}

#Checks the fsid value of the ceph dump with quattor value
sub cluster_fsid_check {
    my ($self, $cluster, $clname) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monhash = decode_json($jstr);
    my $fsid = $monhash->{fsid};
    $self->debug(3, 'fsid from mon dump is '.$fsid);
    if ($cluster->{config}->{fsid} ne $fsid) {
        $self->error("fsid of $clname not matching! ", 
            "Quattor value: $cluster->{config}->{fsid}, ", 
            "Cluster value: $fsid");
        return 0;
    } else {
        return 1;
    }
}

#generate mon hosts
sub gen_extra_config {
    my ($self, $cluster) = @_;
    my $config = $cluster->{config};
    $config->{mon_host} = [];
    foreach my $host (sort(keys(%{$cluster->{monitors}}))) {
        push (@{$config->{mon_host}}, $cluster->{monitors}->{$host}->{fqdn});
    }
    if (!$config->{osd_crush_update_on_start}) {
        $config->{osd_crush_update_on_start} = $cluster->{crushmap} ? 0 : 1 ;
    }
    my @allhosts = @{$config->{mon_host}};
    while(my ($host, $osd) = each(%{$cluster->{osdhosts}})) { 
        push (@allhosts, $osd->{fqdn});
    }
    while(my ($host, $mds) = each(%{$cluster->{mdss}})) { 
        push (@allhosts, $mds->{fqdn});
    }
    my @uniquehosts = keys({map {($_ => 1)} @allhosts}); 
    $cluster->{allhosts} = \@uniquehosts;
                          
}

# Checks if the versions of ceph and ceph-deploy are compatible
sub check_versions {
    my ($self, $qceph, $qdeploy) = @_;
    $self->use_cluster;
    my $cversion = $self->run_ceph_command([qw(--version)]);
    my @vl = split(' ',$cversion);
    my $cephv = $vl[2];
    my ($stdout, $deplv) = $self->run_ceph_deploy_command([qw(--version)]);
    if ($deplv) {
        chomp($deplv);
    }
    if ($qceph && (!match_glob($qceph, $cephv))) {
        $self->error("Ceph version not corresponding! ",
            "Ceph: $cephv, Quattor: $qceph");
        return 0;
    }        
    if ($qdeploy && (!match_glob($qdeploy, $deplv))) {
        $self->error("Ceph-deploy version not corresponding! ",
            "Ceph-deploy: $deplv, Quattor: $qdeploy");
        return 0;
    }
    return 1;
}

# Prepare for ceph-deploy and cluster actions
sub do_prepare_cluster {
    my ($self, $cluster, $gvalues) = @_;
    $self->gen_extra_config($cluster);
    my $qtmp;
    if ($gvalues->{is_deploy}) {
        $qtmp = $self->init_qdepl($cluster->{config}, $gvalues->{cephusr}) or return 0;
        $gvalues->{qtmp} = $qtmp;
        my $clexists = $self->cluster_exists_check($cluster, $gvalues->{cephusr}, $gvalues->{clname});
        my $cfgfile = "$gvalues->{cephusr}->{homeDir}/$gvalues->{clname}.conf";
        $self->write_config($cluster->{config}, $cfgfile) or return 0;
        if (!$clexists) {
            return 0;
        }   
    }
    $self->cluster_ready_check($cluster, $gvalues->{is_deploy}, $gvalues->{hostname}) or return 0;  
    $self->cluster_fsid_check($cluster, $gvalues->{clname}) or return 0;  

}

# Main method for configuring the ceph cluster. 
# use_cluster sets the active cluster
# do_prepare_cluster checks the cluster_existence and prepares the cluster for ceph-deploy, 
# and writes the config file from quattor (but does not install it)
# do_config_actions checks the config from and distribuate the configfile to the hosts.
# do_daemon_actions checks daemons and create/change/remove when needed.
# do_crush_actions builds and installs the crushmap
sub do_configure {
    my ($self, $cluster, $gvalues) = @_;
    $self->use_cluster($gvalues->{clname}) or return 0;
    $self->debug(1,"preparing cluster");
    $self->do_prepare_cluster($cluster, $gvalues) or return 0; 
    $self->debug(1,"checking configuration");
    $self->do_config_actions($cluster, $gvalues) or return 0;
    $self->debug(1,"configuring daemons");
    $self->do_daemon_actions($cluster, $gvalues) or return 0;
    $self->debug(1,"configuring crushmap");
    $self->do_crush_actions($cluster, $gvalues) or return 0; 
    $self->debug(1,'Done');
    return 1;
}
    

sub Configure {
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    my $cephusr = $config->getElement('/software/components/accounts/users/ceph')->getTree();
    my $group = $config->getElement('/software/components/accounts/groups/ceph')->getTree();
    $cephusr->{gid} = $group->{gid};
    my $hostname = $netw->{hostname};
    $self->debug(5, "Running on host $hostname.");
    $self->check_versions($t->{ceph_version}, $t->{deploy_version}) or return 0;

    while (my ($clus, $cluster) = each(%{$t->{clusters}})) {
        my $is_deploy = $cluster->{deployhosts}->{$hostname} ? 1 : 0 ;
        
        my $gvalues = { 
            clname => $clus,
            hostname => $hostname,
            is_deploy => $is_deploy,
            cephusr => $cephusr
        }; 
        $self->do_configure($cluster, $gvalues) or return 0;
        return 1;
    }
}


1; # Required for perl module!
