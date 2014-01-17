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
use File::Copy qw(move);
use JSON::XS;
use Readonly;
use Config::Tiny;

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
    if ($dir && ($dir eq '#')) {
        unshift (@$command, '--overwrite-conf');
    }
    unshift (@$command, ('/usr/bin/ceph-deploy', '--cluster', $self->{cluster}));
    if (grep(m{[;&>|"']}, @$command) ) {
        $self->error("Invalid shell escapes found in command ", 
         join(" ", @$command));
        return 0;
    }
    if ($dir && ($dir ne '#')) {
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
    my ($self, $file) = @_;
    my $cephcfg = Config::Tiny->new;
    $cephcfg = Config::Tiny->read($file);
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
    return 1;
}

# Compare ceph config with the quattor cluster config
sub process_config {
    my ($self, $qconf) = @_;
    # Run only once?
    my $hosts = $qconf->{mon_initial_members};
    foreach my $host (@{$hosts}) {
        # Set config and make admin host
        $self->set_admin_host($qconf, $host) or return 0;
    }
    return 1;
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
    my $pullfile = $self->{qtmp} . $self->{cluster} . '.conf';
    my $hostfile = $pullfile . '.' . $host;
    if (-e $pullfile) {
        move($pullfile, $pullfile . '.old');
    }   
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;
    if (-e $hostfile) {
        move($hostfile, $hostfile . '.old');
    }   
    move($pullfile, $hostfile);
    
    my $cephcfg = $self->get_config($hostfile);

    return $cephcfg;    
}

# Push config to host
sub push_cfg {
    my ($self, $host, $overwrite) = @_;
    if ($overwrite) {
        return $self->run_ceph_deploy_command([qw(config push), $host], '#' );
    }else {
        return $self->run_ceph_deploy_command([qw(config push), $host] );
    }     
}

# Pulls config from host, compares it with quattor config and pushes the config back if needed
sub pull_compare_push {
    my ($self, $config, $host) = @_;
    my $cconf = $self->pull_cfg($host);
    if (!$cconf) {
        return $self->push_cfg($host);
        
    } else {
        $self->{comp} = 1;
        $self->debug(3, %$cconf);
        $self->ceph_quattor_cmp('cfg', $config, $cconf) or return 0;
        if ($self->{comp}== 1) {
            #Config the same, no push needed
            return 1;
        } elsif ($self->{comp}== -1) {
            return $self->push_cfg($host,1);
        } else {# 0 already catched
            $self->error('No valid value returned after comparison');
            return 0;
        }
    }    
}
# Prepare the commands to change a global config entry
sub config_cfgfile {
    my ($self,$action,$name,$values) = @_;
    if ($name eq 'fsid') {
        if ($action ne 'change'){
            $self->error("config has no fsid!");
            return 0;
        } else {
            if ($values->[0] ne $values->[1]) {
                $self->error("config has different fsid!");
                return 0;
            } else {
                return 1
            }
        }
    }   
    if ($action eq 'add'){
        $self->info("$name added to config file\n");
        if ($name eq 'mon_initial_members'){
            $values = join(',',@$values); 
        }
        $self->{comp} = -1;

    } elsif ($action eq 'change') {
        my $quat = $values->[0];
        my $ceph = $values->[1];
        if ($name eq 'mon_initial_members'){
            $quat = join(',',@$quat); 
        }
        #TODO: check if changes are valid
        if ($quat ne $ceph) {
            $self->info("$name changed from $ceph to $quat\n");
            $self->{comp} = -1;
        }
    } elsif ($action eq 'del'){
        #TODO If we want to keep the existing configuration settings that are not in Quattor, we need to log it here
        $self->info("$name not in quattor\n");
        $self->info("$name deleted from config file\n");
        $self->{comp} = -1;
        
    } else {
        $self->error("Action $action not supported!");
        return 0;
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
    my ($self, $cfg, $cfgfile ) = @_;
    my $tinycfg = Config::Tiny->new;
    my $config = { %$cfg };
    foreach my $key (%{$config}) {
        if (ref($config->{$key}) eq 'ARRAY'){ #For mon_initial_members
            $config->{$key} = join(',',@{$config->{$key}});
            $self->debug(3,$config->{$key});
        }
    }
    $tinycfg->{global} = $config;
    if (!$tinycfg->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile!\n"); 
        return 0;
    }
    $self->debug(2,"content writen to config file $cfgfile!\n");
    return 1;
}

# Deploy daemons 
sub do_deploy {
    my ($self) = @_;
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
    $self->print_man_cmds();
    return 1;
}

# Print out the commands that should be run manually
sub print_man_cmds {
    my ($self) = @_;
    if ($self->{man_cmds} && @{$self->{man_cmds}}) {
        $self->info("Commands to be run manually:\n");
        while (my $cmd = shift @{$self->{man_cmds}}) {
            $self->info(join(" ", @$cmd) . "\n");
        }
    }
}

#Set config and Make a temporary directory for push and pulls
sub init_qdepl {
    my ($self, $cephusr, $config) = @_;
    my $qdir = $cephusr->{homeDir} . '/quattor/' ;
    mkdir -p $qdir;
    chown $cephusr->{uid}, $cephusr->{uid}, ($qdir);

    $self->{qtmp} = $qdir; 
    
    $self->write_config($config,$cephusr->{homeDir} . '/' . $self->{cluster} . '.conf' ) or return 0; 
}
   
#Initialize array buckets
sub init_commands {
    my ($self) = @_;
    $self->{deploy_cmds} = [];
    $self->{ceph_cmds} = [];
    $self->{daemon_cmds} = [];
    $self->{man_cmds} = [];
}

#Checks if cluster is configured on this node.
#Prepares ceph ceploy if applicable 
#Fail if cluster not ready and no deploy hosts
sub cluster_ready_check {
    my ($self, $cluster, $cephusr) = @_;
    if ($self->{is_deploy}) { 
        # Check If something is not configured or there is no existing cluster 
        my $hosts = $cluster->{config}->{mon_initial_members};
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
            # Set config file in place and prepare ceph-deploy
            $self->init_qdepl($cephusr, $cluster->{config}) or return 0;
        }
    }    
    if (!$self->run_ceph_command([qw(status)])) {
        #    && ($self->{lasterr} =~ 'Error initializing cluster client: Error')) {
        if ($self->{is_deploy}) {
            if (!$self->set_admin_host($cluster->{config},$self->{hostname})) {
                $self->error("Cannot connect to ceph cluster!\n"); #This should not happen
                return 0;
                }
        } else {
            $self->error("Cluster not configured and no ceph deploy host.." . 
                "Run on a deploy host!\n"); 
        }
        return 0;
    }
    if ($cluster->{config}->{fsid} ne $self->get_fsid()) {
        $self->error("fsid of $self->{cluster} not matching!\n");
        return 0;
    }
    return 1;
}

#Make all defined hosts ceph admin hosts (=able to run ceph commands)
#This is not (necessary) the same as ceph-deploy hosts!
# Also deploy config file
sub set_admin_host {
    my ($self, $config, $host) = @_;
    if ($self->{is_deploy}) {
        $self->pull_compare_push($config, $host) or return 0;
        my @admins=qw(admin);
        push(@admins, $host);
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
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    my $user = $config->getElement('/software/components/accounts/users/ceph')->getTree();
    $self->{hostname} = $netw->{hostname};
    #$self->{fqdn} = $netw->{hostname} . "." . $netw->{domainname};
    foreach my $clus (keys %{$t->{clusters}}){
        $self->use_cluster($clus) or return 0;
        my $cluster = $t->{clusters}->{$clus};
        $self->{is_deploy} = $cluster->{deployhosts}->{$self->{hostname}} ? 1 : '' ;
        if (!$self->cluster_ready_check($cluster, $user)) {
            $self->print_man_cmds();
            return 0; 
        }       
        $self->debug(1,"checking configuration\n");
        $self->check_configuration($cluster) or return 0;
        $self->debug(1,"deploying commands\n");
        $self->do_deploy() or return 0; 
        $self->debug(1,"rechecking configuration\n");
        $self->check_configuration($cluster) or return 0;
        $self->print_man_cmds();
        #TODO: list commands that didn't run successfully (=are still in the arrays)
        return 1;
    }
}


1; # Required for perl module!
