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
#use File::Copy;
use JSON::XS;
use Readonly;
use Config::Tiny;

Readonly::Scalar my $CFGPATH => '/etc/ceph/';
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
    $self->{cfgfile} = $CFGPATH . $cluster . '.conf';
}

# run a command and return the output
sub run_command {
    my ($self, $command) = @_;
    my ($cmd_output, $cmd_err);
    $self->debug(2, join(" ",@$command));
    my $cmd = CAF::Process->new($command, log => $self, 
        stdout => \$cmd_output, stderr => \$cmd_err);
    $cmd->execute();
    my $rc = $?;
    if (!$cmd_output) {
        $cmd_output = '<none>';
    }
    if ($rc) {
        $self->error("Command failed. Error Message: $cmd_err\n" . 
            "Command output: $cmd_output\n");
        $self->{lasterr} = $cmd_err;
        return 0;
    } else {
        $self->debug(2,"Command output: $cmd_output\n");
        if ($cmd_err) {
            $self->warn("Command stderr output: $cmd_err\n");
            $self->{lasterr} = $cmd_err;
        }    
    }
    return $cmd_output;
}

# run a command prefixed with ceph and return the output in json format
sub run_ceph_command {
    my ($self, $command) = @_;
    unshift (@$command, qw(/usr/bin/ceph -f json));
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
    my ($self, $command, $dir) = @_;
    # run as user configured for 'ceph-deploy'
    unshift (@$command, ('/usr/bin/ceph-deploy', '--cluster', $self->{cluster}));
    if (grep(m{[;&>|"']}, @$command) ) {
        $self->error("Invalid shell escapes found in command ", 
         join(" ", @$command));
        return 0;
    }
    if ($dir) {
        if (grep(m{[;&>|"']}, $dir)) {
            $self->error("Invalid shell escapes found in directory ", 
             join(" ", $dir));
            return 0;
        }    
        unshift (@$command, ('cd', $dir, '&&'));
    }
    $command = [join(' ',@$command)];
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
    my $cephcfg = Config::Tiny->new;
    $cephcfg = Config::Tiny->read($self->{cfgfile});
    if (!$cephcfg->{global}) {
        $self->error("Not a valid config file found");
        return 0;
    }
    return $cephcfg->{global};
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
            $self->config_daemon($type,'change',$qkey,$pair) or return 0;
            delete $cephh->{$qkey};
        } else {
            $self->config_daemon($type, 'add',$qkey,$quath->{$qkey}) or return 0;
        }
    }
    foreach my $ckey (keys %{$cephh}) {
        $self->config_daemon($type,'del',$ckey,$cephh->{$ckey}) or return 0;
    }        
    return 'ok';
}

# Compare ceph config with the quattor cluster config
sub process_config {
    my ($self, $qconf) = @_;
    my $cconf = $self->get_config() or return 0;
    $self->debug(3,%$qconf);
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

# Pull config from host
sub pull_cfg {
    my ($self, $host) = @_;
    my $pullfile = $self->{qtmp} . 'ceph.conf';
    my $hostfile = $pullfile . '.' . $host;
    if (-e $pullfile) {
        move($pullfile, $pullfile . '.bak');
    }   
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;
    if (-e $hostfile) {
        move($hostfile, $hostfile . '.bak');
    }   
    move($pullfile, $hostfile);
    
    my $cephcfg = Config::Tiny->new;

    
}
# Prepare the commands to change a global config entry
sub config_cfgfile {
    my ($self,$action,$name,$values) = @_;
    if ($action eq 'add'){
        $self->info("$name added to config file\n");
        if ($name eq 'mon_initial_members'){
            $values = join(',',@$values); 
        }
        $self->{cephgcfg}->{$name} = $values;

    } elsif ($action eq 'change') {
        my $quat = $values->[0];
        my $ceph = $values->[1];
        if ($name eq 'mon_initial_members'){
            $quat = join(',',@$quat); 
        }
        #TODO: check if changes are valid
        if ($quat ne $ceph) {
            $self->info("$name changed from $ceph to $quat\n");
        }
        $self->{cephgcfg}->{$name} = $quat;        
    } elsif ($action eq 'del'){
        # If we want only quattor settings: Deletion not needed, we made a new one
        #$self->info("$name deleted from config file\n");
        # If we want to keep the existing configuration settings that are not in Quattor:
        $self->info("$name not in quattor\n");
        $self->config_cfgfile('add',$name,$values)
    } else {
        $self->error("Action $action not supported!");
    }
    return 1; 
}

# Prepare the commands to change/add/delete a monitor  
sub config_mon {
    my ($self,$action,$name,$daemonh) = @_;
    if ($action eq 'add'){
        my @command = qw(mon create);
        push (@command, $name);
        push (@{$self->{deploy_cmds}}, [@command]);
    } elsif ($action eq 'del') {
        my @command = qw(mon destroy);
        push (@command, $name);
        push (@{$self->{man_cmds}}, [@command]);
    } elsif ($action eq 'change') { #compare config
        my $quatmon = $daemonh->[0];
        my $cephmon = $daemonh->[1];
        # checking immutable attributes
        my @monattrs = ();
        foreach my $attr (@monattrs) {
            if ($quatmon->{$attr} ne $cephmon->{$attr}){
                $self->error("Attribute $attr of $name not corresponding\n");
                return 0;
            }
        }
        if ($cephmon->{addr} =~ /0\.0\.0\.0:0/) { #Initial (unconfigured) member
               $self->config_mon('add', $quatmon);
        }
        if (($name eq $self->{hostname}) and ($quatmon->{up} xor $cephmon->{up})){
            my @command; 
            if ($quatmon->{up}) {
                @command = qw(start); 
            } else {
                @command = qw(stop);
            }
            push (@command, "mon.$name");
            push (@{$self->{daemon_cmds}}, [@command]);
        }
    }
    else {
        $self->error("Action $action not supported!");
    }
    return 1;   
}

# Prepare the commands to change/add/delete an osd
sub config_osd {
    my ($self,$action,$name,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
   
    } else {

    } 
}

# Prepare the commands to change/add/delete an msd
sub config_msd {
    my ($self,$action,$name,$daemonh) = @_;
    # TODO implement
    if ($action eq 'add'){
    
    } elsif ($action eq 'del') {
    
    } else {

    } 
}


# Configure on a type basis
sub config_daemon {
    my ($self, $type,$action,$name,$daemonh) = @_;
    if ($type eq 'cfg'){
        $self->config_cfgfile($action,$name,$daemonh);
    }
    elsif ($type eq 'mon'){
        $self->config_mon($action,$name,$daemonh);
    }
    elsif ($type eq 'osd'){
        $self->config_osd($action,$name,$daemonh);
    }
    elsif ($type eq 'msd'){
        $self->config_msd($action,$name,$daemonh);
    } else {
        $self->error("No such type: $type\n");
    }
}

# Write the config file
sub write_config {
    my ($self, $cfgfile ) = @_;
    $self->{cephcfg}->{global} = $self->{cephgcfg};
    if (!$self->{cephcfg}->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile!\n"); 
        return 0;
    }
    $self->debug(2,"content writen to config file $cfgfile!\n" . %{$self->{cephcfg}});
    #Add newline?
    return 1;
}

# Push new config to ceph cluster
sub do_deploy {
    my ($self) = @_;
    # TODO implement:    
    #   - configuration changes (injection or with restarting daemons (sequentially)?)
    #   - deploy new osds/mons/msd daemons
    #   - list commands for changed/removed daemons
    if ($self->{cephgcfg}) {
        if ($self->{is_deploy}) {
            $self->write_config($self->{cfgfile}) or return 0;
        } 
    }       
    if ($self->{is_deploy}){ #Run only on deploy host(s)
        $self->info("Running ceph-deploy commands.\n");
        while (my $cmd = shift @{$self->{deploy_cmds}}) {
            $self->run_ceph_deploy_command($cmd) or return 0;
        }
    } else {
        $self->info("host is no deployhost, skipping ceph-deploy commands.\n");
        $self->{deploy_cmds} = [];
    }
    while (my $cmd = shift @{$self->{ceph_cmds}}) {
        $self->run_ceph_command($cmd) or return 0;
    }
    while (my $cmd = shift @{$self->{daemon_cmds}}) {
        $self->run_daemon_command($cmd) or return 0;
    }
    $self->info("Commands to be run manually:\n");
    while (my $cmd = shift @{$self->{man_cmds}}) {
        $self->info(join(" ", @$cmd) . "\n");
    }
    return 1;
}

#Make a temporary directory for push and pulls
sub init_qdepl {
    my ($self, $cephusr) = @_;
    my $qdir = $cephusr->{homeDir} . '/quattor' ;
    mkdir -p $qdir;
    chown $cephusr->uid, $cephusr->uid, ($qdir);

    $self->{qtmp} = $qdir; 
  
}   
#Initialize array buckets
sub init_commands {
    my ($self) = @_;
    $self->{cephcfg} = Config::Tiny->new;
    $self->{cephgcfg} = {};
    $self->{deploy_cmds} = [];
    $self->{ceph_cmds} = [];
    $self->{daemon_cmds} = [];
    $self->{man_cmds} = [];
}

#Checks if cluster is configured on this node.
#If not try to get config of other node or give commands to create cluster
#Fail if cluster not ready and no deploy hosts
sub cluster_ready_check {
    my ($self, $hosts) = @_;
    if ($self->{is_deploy} && !$self->run_ceph_deploy_command([qw(admin), $self->{hostname}])) { 
        # Something is not configured or there is no existing cluster 
        my $ok= 0;
        my $okhost;
        $self->{inner} = 1;
        foreach my $host (@{$hosts}) {
            if ($self->run_ceph_deploy_command([qw(gatherkeys), $host])) {
                $ok = 1;
                $okhost = $host;
                last;
            }    
        }
        if (!$ok) {
            # Manual commando's for new cluster  
            # Push to deploy_cmds (and pre-run dodeploy) for automation, 
            # but take care of race conditions
            my @newcmd = qw(new);
            foreach my $host (@{$hosts}) {
                push (@newcmd, $host);
            }
            push (@{$self->{man_cmds}}, [@newcmd]);

            foreach my $host (@{$hosts}) {
                my @moncr = qw(mon create);
                push (@moncr, $host);
                push (@{$self->{man_cmds}}, [@moncr]);
            }
            return 0;
        } else {
            $self->run_ceph_deploy_command([qw(config pull), $okhost]) or return 0;
            $self->run_ceph_deploy_command([qw(admin), $self->{hostname}]) or return 0;
        }
    }    
    if (!$self->run_ceph_command([qw(status)]) 
            && ($self->{lasterr} =~ 'Error initializing cluster client: Error')) {
        if ($self->{is_deploy}) {
            $self->error("Cannot connect to ceph cluster!\n"); #This should not happen
        } else {
            $self->error("Cluster not configured and no ceph deploy host.." . 
                "Run on a deploy host!\n"); 
        }
        return 0;
    }
    return 1;
}

#Make all defined hosts ceph admin hosts (=able to run ceph commands)
#This is not (necessary) the same as ceph-deploy hosts!
sub set_admin_hosts {
    my ($self, $hosts) = @_;
    if ($self->{is_deploy}) {
        my @admins=qw(admin);
        foreach my $mon (keys %{$hosts}) {
            push(@admins, $mon);
        }
        $self->run_ceph_deploy_command(\@admins); 
    }
}
# Compare the configuration (and prepare commands) 
sub check_configuration {
    my ($self, $cluster) = @_;
    $self->init_commands();
    $self->process_config($cluster->{config}) or return 0;
    $self->process_mons($cluster->{monitors}) or return 0;
#    $self->process_osds($cluster->{osdhosts}) or return 0;
#    if ($cluster->{msds}) {
#        $self->process_msds($cluster->{msds}) or return 0;
#    }
    return 1;
}
        
sub Configure {
    my ($self, $config) = @_;
    $self->info($self->run_command([qw(cd /home/kwaegema)]));
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    $self->{hostname} = $netw->{hostname};
    #$self->init_qdepl($config->getElement('/software/components/accounts/users/ceph')->getTree());
    #$self->{fqdn} = $netw->{hostname} . "." . $netw->{domainname};
    foreach my $clus (keys %{$t->{clusters}}){
        $self->use_cluster($clus) or return 0;
        my $cluster = $t->{clusters}->{$clus};
        $self->{is_deploy} = $cluster->{deployhosts}->{$self->{hostname}} ? 1 : '' ;
        $self->cluster_ready_check($cluster->{config}->{mon_initial_members}) or return 0;
        if ($cluster->{config}->{fsid} ne $self->get_fsid()) {
            $self->error("fsid of $clus not matching!\n");
            return 0;
        }
       
        $self->debug(1,"checking configuration\n");
        $self->check_configuration($cluster) or return 0;
        $self->debug(1,"deploying commands\n");
        $self->do_deploy() or return 0; 
        $self->set_admin_hosts($cluster->{monitors});
        $self->set_admin_hosts($cluster->{osdhosts});
        $self->debug(1,"rechecking configuration\n");
        $self->check_configuration($cluster) or return 0;
        $self->info("Commands to be run manually:\n");
        while (my $cmd = shift @{$self->{man_cmds}}) {
            $self->info(join(" ", @$cmd) . "\n");
        }
        #TODO: list commands that didn't run successfully (=are still in the arrays)
        return 1;
    }
}


1; # Required for perl module!
