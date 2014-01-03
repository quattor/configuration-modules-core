# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;
use LC::Find;
use LC::File qw(copy makedir);

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use File::Path;
use JSON::XS;
use Readonly;

our $EC=LC::Exception::Context->new->will_store_all;

#set the working cluster, (if not given, use the default cluster 'ceph')
sub use_cluster {
    my ($self, $cluster) = @_;
    $cluster ||= 'ceph';
    if ($cluster ne 'ceph') {
        $self->error("Not yet implemented!\n"); 
        return 0;
    }
    $self->{cluster} = $cluster;
}

# run a command and return the output
sub run_command {
    my ($self, $command) = @_;
    my ($cmd_output, $cmd_err);
    my $cmd = CAF::Process->new($command, log => $self, 
        stdout => \$cmd_output, stderr => \$cmd_err);
    $cmd->execute();
    if ($?) {
        $self->error("Command failed. Error Message: $cmd_err\n" . 
            "Command output: $cmd_output\n");
        return 0;
    } else {
        $self->debug(1,"Command output: $cmd_output\n");
        if ($cmd_err) {
            $self->warn("Command stderr output: $cmd_err\n");
        }    
    }
    return $cmd_output;
}

# run a command prefixed with ceph and return the output in json format
sub run_ceph_command {
    my ($self, $command) = @_;
    unshift (@$command, qw(ceph -f json));
    push (@$command, ('--cluster', $self->{cluster}));
    return $self->run_command($command);
}

sub run_daemon_command {
    my ($self, $command) = @_;
    unshift (@$command, qw(/etc/init.d/ceph));
    return $self->run_command($command);
}

# run a command prefixed with ceph-deploy and return the output (no json)
sub run_ceph_deploy_command {
    my ($self, $command) = @_;
    # run as user configured for 'ceph-deploy'
    unshift (@$command, qw(ceph-deploy));
    push (@$command, ('--cluster', $self->{cluster}));
    if (grep(m{[;&>|"']}, @$command)) {
        $self->error("Invalid shell escapes found in command ",
         join(" ", @$command));
    }
    $command = ["'" . join(' ',@$command) . "'"];
    unshift (@$command, qw(su - ceph -c));
    return $self->run_command($command);
}

## Retrieving information of ceph cluster

# Gets the fsid of the cluster
sub get_fsid {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monhash = decode_json($jstr);
    return $monhash->{fsid};
}

# Gets the config of the cluster
sub get_config {
    my ($self) = @_;
    # TODO implement fileread
}

# Gets the OSD map
sub osd_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(osd tree)]) or return 0;
    my $osdtree = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(osd dump)]) or return 0;
    my $osddump = decode_json($jstr);  
    # TODO implement
    # my %osdparsed = {};
}
    
# Gets the MON map
sub mon_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monsh = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(quorum_status)]) or return 0;
    my $monstate = decode_json($jstr);
    my %monparsed = ();
    foreach my $mon (@{$monsh->{mons}}){
        $mon->{up} = $mon->{name} ~~ @{$monstate->{quorum_names}};
        $monparsed{$mon->{name}} = $mon;
    }
    return \%monparsed;
}
# Gets the MSD map 
sub msd_hash {
     my ($self) = @_;
    # TODO implement
}       
## Processing and comparing between Quattor and Ceph

# Do a comparison of quattor config and the actual ceph config 
# for a given type (cfg, mon, osd, msd)
sub ceph_quattor_cmp {
    my ($self, $type, $quath, $cephh) = @_;
    foreach my $qkey (keys %{$quath}) {
        if (exists $cephh->{$qkey}) {
            my $pair = [$quath->{$qkey}, $cephh->{$qkey}];
            #check attrs and reconfigure
            $self->config_daemon($type,'change', $pair) or return 0;
            delete $cephh->{$qkey};
        } else {
            $self->config_daemon($type, 'add',$quath->{$qkey}) or return 0;
        }
    }
    foreach my $ckey (keys %{$cephh}) {
        $self->config_daemon($type,'del',$cephh->{$ckey}) or return 0;
    }        
    return 'ok';
}

# Compare ceph config with the quattor cluster config
sub process_config {
    my ($self, $qconf) = @_;
    my $cconf = $self->get_config() or return 0;
    return $self->ceph_quattor_cmp('cfg', $qconf, $cconf);
}

# Compare ceph mons with the quattor mons
sub process_mons {
    my ($self, $qmons) = @_;
    my $cmons = $self->mon_hash() or return 0;
    return $self->ceph_quattor_cmp('mon', $qmons, $cmons);
}

# Compare cephs osd with the quattor osds
sub process_osds {
    my ($self, $qosds) = @_;
    my $cosds = $self->osd_hash() or return 0;
    return $self->ceph_quattor_cmp('osd', $qosds, $cosds);
}

# Compare cephs msd with the quattor msds
sub process_msds {
    my ($self, $qmsds) = @_;
    my $cmsds = $self->msd_hash() or return 0;
    return $self->ceph_quattor_cmp('msd', $qmsds, $cmsds);
}

# Prepare the commands to change a config entry
sub config_cfgfile {
    my ($self, $action,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
    
    } else {

    } 
}

# Prepare the commands to change/add/delete a monitor  
sub config_mon {
    my ($self, $action,$daemonh) = @_;
    if ($action eq 'add'){
        my @command = qw(mon create);
        push (@command, $daemonh->{name});
        push (@{$self->{deploy_cmds}}, [@command]);
    } elsif ($action eq 'del') {
        my @command = qw(mon destroy);
        push (@command, $daemonh->{name});
        push (@{$self->{man_cmds}}, [@command]);
    } else { #compare config
        my $quatmon = $daemonh->[0];
        my $cephmon = $daemonh->[1];
        # checking immutable attributes
        my @monattrs = ('name');
        foreach my $attr (@monattrs) {
            if ($quatmon->{$attr} ne $cephmon->{$attr}){
                $self->error("Attribute $attr of $quatmon->{name} not corresponding");
                return 0;
            }
        }
        if ($quatmon->{up} ne $cephmon->{up}){
            my @command; 
            if ($quatmon->{up}) {
                @command = qw(start); 
            } else {
                @command = qw(stop);
            }
            push (@command, "mon.$quatmon->{name}");
            push (@{$self->{daemon_cmds}}, [@command]);
        }
    }
    return 1;   
}

# Prepare the commands to change/add/delete an osd
sub config_osd {
    my ($self, $action,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
    
    } else {

    } 
}

# Prepare the commands to change/add/delete an msd
sub config_msd {
    my ($self, $action,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
    
    } else {

    } 
}


# Configure on a type basis
sub config_daemon {
    my ($self, $type,$action,$daemonh) = @_;
    if ($type eq 'cfg'){
        $self->config_cfgfile($action,$daemonh);
    }
    elsif ($type eq 'mon'){
        $self->config_mon($action,$daemonh);
    }
    elsif ($type eq 'osd'){
        $self->config_osd($action,$daemonh);
    }
    elsif ($type eq 'msd'){
        $self->config_msd($action,$daemonh);
    else {
        $self->error("No such type: $type");
    }
}

# Push new config to ceph cluster
sub do_deploy {
    my ($self) = @_;
    # TODO implement:    
    #   - configuration changes (injection or with restarting daemons (sequentially)?)
    #   - deploy new osds/mons/msd daemons
    #   - list commands for changed/removed daemons 
    if (%{$self->{cfgchanges}}){
        # TODO implement
        return 0;
    }
    if ($self->{is_deploy}){ #Run only on deploy host(s)
        while (my $cmd = shift @{$self->{deploy_cmds}}) {
            $self->run_ceph_deploy_command($cmd) or return 0;
        }
    } else {
        $self->{deploy_cmds} = [];
    }
    while (my $cmd = shift @{$self->{ceph_cmds}}) {
        $self->run_ceph_command($cmd) or return 0;
    }
    while (my $cmd = shift @{$self->{daemon_cmds}}) {
#TODO: test  
        $self->run_daemon_command($cmd) or return 0;
    }
    return 1;
}
    
#Initialize array buckets
sub init_commands {
    my ($self) = @_;
    $self->{cfgchanges} = {};
    $self->{deploy_cmds} = [];
    $self->{ceph_cmds} = [];
    $self->{daemon_cmds} = [];
    $self->{man_cmds} = [];
}

# Compare the configuration (and prepare commands) 
sub check_configuration {
    my ($self, $cluster) = @_;
    $self->init_commands();
    $self->process_config($cluster->{config}) or return 0;
    $self->process_mons($cluster->{monitors}) or return 0;
    $self->process_osds($cluster->{osdhosts}) or return 0;
    if ($cluster->{msds}) {
        $self->process_msds($cluster->{msds}) or return 0;
    }
    return 1;
}
        
sub Configure {
    my ($self, $config) = @_;

    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    foreach my $clus (keys %{$t->{clusters}}){
        $self->use_cluster($clus) or return 0;
        my $cluster = $t->{clusters}->{$clus};
        if ($cluster->{config}->{fsid} ne $self->get_fsid()) {
            $self->error("fsid of $clus not matching!\n");
            return 0;
        }
        $self->{is_deploy} = 'true'; #TODO: from quattor
        $self->check_configuration($cluster);
        $self->do_deploy(); 
        # recheck config
        $self->check_configuration($cluster);
        if (@{$self->{man_cmds}}) {
            #TODO: print this
        }

    }
}

1; # Required for perl module!
