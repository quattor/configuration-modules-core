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

use base qw(NCM::Component);

use LC::Exception;
use LC::Find;
use LC::File qw(makedir);

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
# taint-safe since 1.23;
# Packages @ http://www.city-fan.org/ftp/contrib/perl-modules/RPMS.rhel6/ 
# Attention: Package has some versions like 1.2101 and 1.2102 .. 
use Data::Compare 1.23 qw(Compare);
use Data::Dumper;
use Config::Tiny;
use EDG::WP4::CCM::Element qw(unescape);
use File::Basename;
use File::Path qw(make_path);
use File::Copy qw(copy move);
use List::Util qw( min max );
use JSON::XS;
use Readonly;

our $EC=LC::Exception::Context->new->will_store_all;
Readonly::Array my @NONINJECT => qw(
    mon_host 
    mon_initial_members
    public_network
    filestore_xattr_use_omap
);
Readonly my $OSDBASE => qw(/var/lib/ceph/osd/);
Readonly my $JOURNALBASE => qw(/var/lib/ceph/log/);
Readonly my $CRUSH_TT_FILE => 'ceph/crush.tt';

#set the working cluster, (if not given, use the default cluster 'ceph')
sub use_cluster {
    my ($self, $cluster) = @_;
    undef $self->{fsid};
    $cluster ||= 'ceph';
    if ($cluster ne 'ceph') {
        $self->error("Not yet implemented!"); 
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
        $self->error("Command failed. Error Message: $cmd_err");
        if ($cmd_output) {
            $self->verbose("Command output: $cmd_output");
        }
        return;
    } else {
        if ($cmd_output) {
            $self->verbose("Command output: $cmd_output");
        }
        if ($cmd_err) {
            $self->verbose("Command stderr output: $cmd_err");
        }    
    }
    #return $cmd_output || "0 but true";
    return wantarray ? ($cmd_output, $cmd_err) : ($cmd_output || "0E0");
}

# run a command prefixed with ceph and return the output in json format
sub run_ceph_command {
    my ($self, $command) = @_;
    return $self->run_command([qw(/usr/bin/ceph -f json --cluster), $self->{cluster}, @$command]);
}

sub run_daemon_command {
    my ($self, $command) = @_;
    return $self->run_command([qw(/sbin/service ceph), @$command]);
}

#checks for shell escapes
sub has_shell_escapes {
    my ($self, $cmd) = @_;
    if (grep(m{[;&>|"']}, @$cmd) ) {
        $self->error("Invalid shell escapes found in ", 
            join(" ", @$cmd));
        return 0;
    }
    return 1;
}
    
#Runs a command as the ceph user
sub run_command_as_ceph {
    my ($self, $command, $dir) = @_;
    
    $self->has_shell_escapes($command) or return; 
    if ($dir) {
        $self->has_shell_escapes([$dir]) or return;
        unshift (@$command, ('cd', $dir, '&&'));
    }
    $command = [join(' ',@$command)];
    return $self->run_command([qw(su - ceph -c), @$command]);
}


# run a command prefixed with ceph-deploy and return the output (no json)
sub run_ceph_deploy_command {
    my ($self, $command, $dir, $overwrite) = @_;
    # run as user configured for 'ceph-deploy'
    if ($overwrite) {
        unshift (@$command, '--overwrite-conf');
    }
    return $self->run_command_as_ceph([qw(/usr/bin/ceph-deploy --cluster), $self->{cluster}, @$command], $dir);
}

## Retrieving information of ceph cluster

# Gets the fsid of the cluster
sub get_fsid {
    my ($self) = @_;
    if (!defined($self->{fsid})){
        my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
        my $monhash = decode_json($jstr);
        $self->{fsid} = $monhash->{fsid};
        $self->debug(3, 'Set fsid from mon dump to '.$self->{fsid});
    }
    $self->debug(2, 'Fsid '.$self->{fsid});
    return $self->{fsid};
}

# Gets the config of the cluster
sub get_global_config {
    my ($self, $file) = @_;
    my $cephcfg = Config::Tiny->new();
    $cephcfg = Config::Tiny->read($file);
    if (scalar(keys %$cephcfg) > 1) {
        $self->error("NO support for daemons not installed with ceph-deploy.",
            "Only global section expected, provided sections: ", join(",", keys %$cephcfg));
    }
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
    my %osdparsed = ();
    foreach my $osd (@{$osddump->{osds}}) {
        my $id = $osd->{osd};
        my ($name,$host);
        foreach my $tosd (@{$osdtree->{nodes}}) {
            if ($tosd->{type} eq 'osd' && $tosd->{id} == $id) {
                $name = $tosd->{name};
            }
            elsif ($tosd->{type} eq 'host' && $id ~~ $tosd->{children}) { # Requires Perl > 5.10 !
                $host = $tosd->{name};
            }
        }
        if (!$name || !$host) {
            $self->error("Parsing osd commands went wrong");
            return 0;
        }
        my @addr = split(':', $osd->{public_addr});
        my $ip = $addr[0];
        my ($osdloc, $journalloc) = $self->get_osd_location($id, $ip, $osd->{uuid}) or return 0;
        my $osdp = { 
            name            => $name, 
            host            => $host, 
            ip              => $ip, 
            id              => $id, 
            uuid            => $osd->{uuid}, 
            up              => $osd->{up}, 
            in              => $osd->{in}, 
            osd_path        => $osdloc, 
            journal_path    => $journalloc 
        };
        my $osdstr = "$host:$osdloc";
        $osdparsed{$osdstr} = $osdp;
    }
    return \%osdparsed;
}

# Get the osd name from the host and path
sub get_osd_name {
    my ($self, $host, $location) = @_;
    my @catcmd = ('/usr/bin/ssh', $host, 'cat');
    my $id = $self->run_command_as_ceph([@catcmd, "$location/whoami"]) or return 0;
    chomp($id);
    $id = $id + 0; # Only keep the integer part
    return "osd.$id";
}   

# Check/gets the OSDs underlying disk/path 
# checks whoami,fsid and ceph_fsid and returns the real path
sub get_osd_location {
    my ($self,$osd, $host, $uuid) = @_;
    my $osdlink = "/var/lib/ceph/osd/$self->{cluster}-$osd";
    if (!$host) {
        $self->error("Can not find osd without a hostname");
        return ;
    }   
    
    # TODO: check if physical exists?
    my @catcmd = ('/usr/bin/ssh', $host, 'cat');
    my $ph_uuid = $self->run_command_as_ceph([@catcmd, $osdlink . '/fsid']);
    chomp($ph_uuid);
    if ($uuid ne $ph_uuid) {
        $self->error("UUID for osd.$osd of ceph command output differs from that on the disk. ",
            "Ceph value: $uuid, ", 
            "Disk value: $ph_uuid");
        return ;    
    }
    my $ph_fsid = $self->run_command_as_ceph([@catcmd, $osdlink . '/ceph_fsid']);
    chomp($ph_fsid);
    my $fsid = $self->get_fsid();
    if ($ph_fsid ne $fsid) {
        $self->error("fsid for osd.$osd not matching with this cluster! ", 
            "Cluster value: $fsid, ", 
            "Disk value: $ph_fsid");
        return ;
    }
    my @loccmd = ('/usr/bin/ssh', $host, '/bin/readlink');
    my $osdloc = $self->run_command_as_ceph([@loccmd, $osdlink]);
    my $journalloc = $self->run_command_as_ceph([@loccmd, '-f', "$osdlink/journal" ]);
    chomp($osdloc);
    chomp($journalloc);
    return $osdloc, $journalloc;

}

# Checks if the disk is empty
sub check_empty {
    my ($self, $loc, $host) = @_;

    my @lscmd = ('/usr/bin/ssh', $host, 'ls', '-1', $loc);
    my $lsoutput = $self->run_command_as_ceph([@lscmd]) or return 0;
    my $lines = $lsoutput =~ tr/\n//;
    if ($lines != 0) {
        $self->error("$loc on $host is not empty!");
        return 0;
    } else {
        return 1;
    }    
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

# Gets the MDS map 
sub mds_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mds stat)]) or return 0;
    my $mdshs = decode_json($jstr);
    my %mdsparsed = ();
    foreach my $mds (values %{$mdshs->{mdsmap}->{info}}) {
        my @state = split(':', $mds->{state});
        my $up = ($state[0] eq 'up') ? 1 : 0 ;
        my $mdsp = {
            name => $mds->{name},
            gid => $mds->{gid},
            up => $up
        };
        $mdsparsed{$mds->{name}} = $mdsp;
    }
    return \%mdsparsed;
}       

## Processing and comparing between Quattor and Ceph

# Do a comparison of quattor config and the actual ceph config 
# for a given type (cfg, mon, osd, mds)
sub ceph_quattor_cmp {
    my ($self, $type, $quath, $cephh) = @_;
    foreach my $qkey (sort(keys %{$quath})) {
        if (exists $cephh->{$qkey}) {
            my $pair = [$quath->{$qkey}, $cephh->{$qkey}];
            #check attrs and reconfigure
            $self->config_daemon($type, 'change', $qkey, $pair) or return 0;
            delete $cephh->{$qkey};
        } else {
            $self->config_daemon($type, 'add', $qkey, $quath->{$qkey}) or return 0;
        }
    }
    foreach my $ckey (keys %{$cephh}) {
        $self->config_daemon($type, 'del', $ckey, $cephh->{$ckey}) or return 0;
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

# Converts a host/osd hierarchy in a 'host:osd' structure
sub flatten_osds {
    my ($self, $hosds) = @_; 
    my %flat = ();
    while (my ($hostname, $host) = each(%{$hosds})) {
        my $osds = $host->{osds};
        while (my ($osdpath, $newosd) = each(%{$osds})) {
            $newosd->{host} = $hostname;
            $newosd->{fqdn} = $host->{fqdn};
            $osdpath = unescape($osdpath);
            if ($osdpath !~ m|^/|){
                $osdpath = $OSDBASE . $osdpath;
            }
            if (exists($newosd->{journal_path}) && $newosd->{journal_path} !~ m|^/|){
                $newosd->{journal_path} = $JOURNALBASE . $newosd->{journal_path};
            }
            $newosd->{osd_path} = $osdpath;
            my $osdstr = "$hostname:$osdpath" ;
            $flat{$osdstr} = $newosd;
        }
    }
    return \%flat;
}
# Compare cephs osd with the quattor osds
sub process_osds {
    my ($self, $qosds) = @_;
    my $qflosds = $self->flatten_osds($qosds);
    $self->debug(5, 'OSD lay-out', Dumper($qosds));
    my $cosds = $self->osd_hash() or return 0;
    return $self->ceph_quattor_cmp('osd', $qflosds, $cosds);
}

# Compare cephs mds with the quattor mds
sub process_mdss {
    my ($self, $qmdss) = @_;
    my $cmdss = $self->mds_hash() or return 0;
    return $self->ceph_quattor_cmp('mds', $qmdss, $cmdss);
}

# Move old config files to old dir with timestamp
sub move_to_old {
    my ($self, $filename) = @_;
    my $origdir = $self->{qtmp};
    my $olddir = $origdir . "old/";
    my $filepath = $origdir . $filename;
    
    if (!-d $olddir) {
        $self->error("Directory $olddir does not exists");
        return 0;
    }
    if (-e $filepath) {
        my $suff = ".old." . time();
        my $newfile = $olddir . $filename . $suff;
        $self->debug('3', "Moving file $filepath to $newfile");
        if (!move($filepath, $newfile)){ 
            $self->error("Moving $filepath to $newfile failed: $!");
            return 0;
        }
    } 
    return 1;
}  
    
# Pull config from host
sub pull_cfg {
    my ($self, $host) = @_;
    my $pullfile = "$self->{cluster}.conf";
    my $hostfile = "$pullfile.$host";
    $self->move_to_old($pullfile) or return 0;
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;
    $self->move_to_old($hostfile) or return 0;

    move($self->{qtmp} . $pullfile, $self->{qtmp} .  $hostfile) or return 0;
    
    my $cephcfg = $self->get_global_config($self->{qtmp} . $hostfile) or return 0;

    return $cephcfg;    
}

# Push config to host
sub push_cfg {
    my ($self, $host, $overwrite) = @_;
    if ($overwrite) {
        return $self->run_ceph_deploy_command([qw(config push), $host],'',1 );
    }else {
        return $self->run_ceph_deploy_command([qw(config push), $host] );
    }     
}

# Makes the changes in the config file realtime by using ceph injectargs
sub inject_realtime {
    my ($self, $host, $changes) = @_;
    my @cmd;
    for my $param (keys %{$changes}) {
        if (!($param ~~ @NONINJECT)) { # Requires Perl > 5.10 !
            @cmd = ('tell',"*.$host",'injectargs','--');
            my $keyvalue = "--$param=$changes->{$param}";
            $self->info("injecting $keyvalue realtime on $host");
            $self->run_ceph_command([@cmd, $keyvalue]) or return 0;
        }
    }
    return 1;
}
# Pulls config from host, compares it with quattor config and pushes the config back if needed
sub pull_compare_push {
    my ($self, $config, $host) = @_;
    my $cconf = $self->pull_cfg($host);
    if (!$cconf) {
        return $self->push_cfg($host);
    } else {
        $self->{cfgchanges} = {};
        $self->debug(3, "Pulled config:", %$cconf);
        $self->ceph_quattor_cmp('cfg', $config, $cconf) or return 0;
        if (!%{$self->{cfgchanges}}) {
            #Config the same, no push needed
            return 1;
        } else {
            $self->push_cfg($host,1) or return 0;
            $self->inject_realtime($host, $self->{cfgchanges}) or return 0;
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
        $self->info("$name added to config file");
        if (ref($values) eq 'ARRAY'){
            $values = join(',',@$values); 
        }
        $self->{cfgchanges}->{$name} = $values;

    } elsif ($action eq 'change') {
        my $quat = $values->[0];
        my $ceph = $values->[1];
        if (ref($quat) eq 'ARRAY'){
            $quat = join(',',@$quat); 
        }
        #TODO: check if changes are valid
        if ($quat ne $ceph) {
            $self->info("$name changed from $ceph to $quat");
            $self->{cfgchanges}->{$name} = $quat;
        }
    } elsif ($action eq 'del'){
        # TODO If we want to keep the existing configuration settings that are not in Quattor, 
        # we need to log it here. For now we expect that every used config parameter is in Quattor
        $self->error("$name not in quattor");
        #$self->info("$name deleted from config file\n");
        return 0;
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
        push (@command, $daemonh->{fqdn});
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
        $self->check_immutables($name, \@monattrs, $quatmon, $cephmon) or return 0;
        
        if ($cephmon->{addr} =~ /^0\.0\.0\.0:0/) { #Initial (unconfigured) member
               $self->config_mon('add', $quatmon);
        }
        $self->check_state($name, $name, 'mon', $quatmon, $cephmon);
        
        my @donecmd = ('/usr/bin/ssh', $quatmon->{fqdn}, 
                       'test','-e',"/var/lib/ceph/mon/$self->{cluster}-$name/done" );
        if (!$cephmon->{up} && !$self->run_command_as_ceph([@donecmd])) {
            # Node reinstalled without first destroying it
            $self->info("Monitor $name shall be reinstalled");
            return $self->config_mon('add',$name,$quatmon);
        }
    }
    else {
        $self->error("Action $action not supported!");
    }
    return 1;   
}
#does a check on unchangable attributes, returns 0 if different
sub check_immutables {
    my ($self, $name, $imm, $quat, $ceph) = @_;
    my $rc =1;
    foreach my $attr (@{$imm}) {
        if ($quat->{$attr} ne $ceph->{$attr}){
            $self->error("Attribute $attr of $name not corresponding.", 
                "Quattor: $quat->{$attr}, ",
                "Ceph: $ceph->{$attr}");
            $rc=0;
        }
    }
    return $rc;
}
# Checks and changes the state on the host
sub check_state {
    my ($self, $id, $host, $type, $quat, $ceph) = @_;
    if (($host eq $self->{hostname}) and ($quat->{up} xor $ceph->{up})){
        my @command; 
        if ($quat->{up}) {
            @command = qw(start); 
        } else {
            @command = qw(stop);
        }
        push (@command, "$type.$id");
        push (@{$self->{daemon_cmds}}, [@command]);
    }
} 
# Prepare the commands to change/add/delete an osd
sub config_osd {
    my ($self,$action,$name,$daemonh) = @_;
    if ($action eq 'add'){
        #TODO: change to 'create' ?
        $self->check_empty($daemonh->{osd_path}, $daemonh->{fqdn}) or return 0;
        $self->debug(2,"Adding osd $name");
        my $prepcmd = [qw(osd prepare)];
        my $activcmd = [qw(osd activate)];
        my $pathstring = "$daemonh->{fqdn}:$daemonh->{osd_path}";
        if ($daemonh->{journal_path}) {
            (my $journaldir = $daemonh->{journal_path}) =~ s{/journal$}{};
            my $mkdircmd = ['/usr/bin/ssh', $daemonh->{fqdn}, 'sudo', '/bin/mkdir', '-p', $journaldir];
            $self->run_command_as_ceph($mkdircmd); 
            $self->check_empty($journaldir, $daemonh->{fqdn}) or return 0; 
            $pathstring = "$pathstring:$daemonh->{journal_path}";
        }
        for my $command (($prepcmd, $activcmd)) {
            push (@$command, $pathstring);
            push (@{$self->{deploy_cmds}}, $command);
        }
    } elsif ($action eq 'del') {
        my @command = qw(osd destroy);
        push (@command, $daemonh->{name});
        push (@{$self->{man_cmds}}, [@command]);
   
    } elsif ($action eq 'change') { #compare config
        my $quatosd = $daemonh->[0];
        my $cephosd = $daemonh->[1];
        # checking immutable attributes
        my @osdattrs = ('host', 'osd_path');
        if ($quatosd->{journal_path}) {
            push(@osdattrs, 'journal_path');
        }
        $self->check_immutables($name, \@osdattrs, $quatosd, $cephosd) or return 0;
        (my $id = $cephosd->{id}) =~ s/^osd\.//;
        $self->check_state($id, $quatosd->{host}, 'osd', $quatosd, $cephosd);
        #TODO: Make it possible to bring osd 'in' or 'out' the cluster ?
    } else {
        $self->error("Action $action not supported!");
    }
    return 1;
}

# Prepare the commands to change/add/delete an mds
sub config_mds {
    my ($self,$action,$name,$daemonh) = @_;
    if ($action eq 'add'){
        my $fqdn = $daemonh->{fqdn};
        my @donecmd = ('/usr/bin/ssh', $fqdn, 'test','-e',"/var/lib/ceph/mds/$self->{cluster}-$name/done" );
        my $mds_exists = $self->run_command_as_ceph([@donecmd]);
        
        if ($mds_exists) { # A down ceph mds daemon is not in map
            if ($daemonh->{up} && ($name eq $self->{hostname})) {
                my @command = ('start', "mds.$name");
                push (@{$self->{daemon_cmds}}, [@command]);
            }
        } else {
            my @command = qw(mds create);
            push (@command, $fqdn);
            push (@{$self->{deploy_cmds}}, [@command]);
        }   
    } elsif ($action eq 'del') {
        my @command = qw(mds destroy);
        push (@command, $name);
        push (@{$self->{man_cmds}}, [@command]);
    
    } elsif ($action eq 'change') {
        my $quatmds = $daemonh->[0];
        my $cephmds = $daemonh->[1];
        # Note: A down ceph mds daemon is not in map
        $self->check_state($name, $name, 'mds', $quatmds, $cephmds);
    } else {
        $self->error("Action $action not supported!");
    }
    return 1;
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
    elsif ($type eq 'mds'){
        $self->config_mds($action,$name,$daemonh);
    } else {
        $self->error("No such type: $type");
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
            $self->debug(3,"Array converted to string:", $config->{$key});
        }
    }
    $tinycfg->{global} = $config;
    if (!$tinycfg->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile: $!", "Exitcode: $?"); 
        return 0;
    }
    $self->debug(2,"content written to config file $cfgfile");
    return 1;
}

# Deploy daemons 
sub do_deploy {
    my ($self) = @_;
    if ($self->{is_deploy}){ #Run only on deploy host(s)
        $self->info("Running ceph-deploy commands.");
        while (my $cmd = shift @{$self->{deploy_cmds}}) {
            $self->debug(1,@$cmd);
            $self->run_ceph_deploy_command($cmd) or return 0;
        }
    } else {
        $self->info("host is no deployhost, skipping ceph-deploy commands.");
        $self->{deploy_cmds} = [];
    }
    while (my $cmd = shift @{$self->{ceph_cmds}}) {
        $self->run_ceph_command($cmd) or return 0;
    }
    while (my $cmd = shift @{$self->{daemon_cmds}}) {
        $self->debug(1,"Daemon command:", @$cmd);
        $self->run_daemon_command($cmd) or return 0;
    }
    $self->print_man_cmds();
    return 1;
}

# Print out the commands that should be run manually
sub print_man_cmds {
    my ($self) = @_;
    if ($self->{man_cmds} && @{$self->{man_cmds}}) {
        $self->info("Commands to be run manually (as ceph user):");
        while (my $cmd = shift @{$self->{man_cmds}}) {
            $self->info(join(" ", @$cmd));
        }
    }
}

#Set config and Make a temporary directory for push and pulls
sub init_qdepl {
    my ($self, $config) = @_;
    my $cephusr = $self->{cephusr};
    my $qdir = $cephusr->{homeDir} . '/ncm-ceph/' ;
    my $odir = $qdir . 'old/' ;
    my $crushdir = $qdir . 'crushmap/' ;
    make_path($qdir, $odir, $crushdir, {owner=>$cephusr->{uid}, group=>$cephusr->{gid}});

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
    my ($self, $cluster) = @_;
    if ($self->{is_deploy}) { 
        # Check If something is not configured or there is no existing cluster 
        my $hosts = $cluster->{config}->{mon_host};
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
            # Manual commands for new cluster  
            # Push to deploy_cmds (and pre-run dodeploy) for automation, 
            # but take care of race conditions
            
            my @newcmd = qw(new);
            foreach my $host (@{$hosts}) {
                push (@newcmd, $host);
            }
            if (!-f "$self->{cephusr}->{homeDir}/$self->{cluster}.mon.keyring"){
                $self->run_ceph_deploy_command([@newcmd]);
            }
            my @moncr = qw(/usr/bin/ceph-deploy mon create-initial);
            push (@{$self->{man_cmds}}, [@moncr]);
            $self->init_qdepl($cluster->{config});
            return 0;
        } else {
            # Set config file in place and prepare ceph-deploy
            $self->init_qdepl($cluster->{config}) or return 0;
        }
    }    
    if (!$self->run_ceph_command([qw(status)])) {
        if ($self->{is_deploy}) {
            if (!$self->set_admin_host($cluster->{config},$self->{hostname}) 
                    || !$self->run_ceph_command([qw(status)])) {
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
    my $fsid = $self->get_fsid();
    if ($cluster->{config}->{fsid} ne $fsid) {
        $self->error("fsid of $self->{cluster} not matching! ", 
            "Quattor value: $cluster->{config}->{fsid}, ", 
            "Cluster value: $fsid");
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
        $self->run_ceph_deploy_command(\@admins,'',1 ); #overwrite for stupid ceph deploy
    }
}
# Compare the configuration (and prepare commands) 
sub check_configuration {
    my ($self, $cluster) = @_;
    $self->init_commands();
    $self->process_config($cluster->{config}) or return 0;
    $self->process_mons($cluster->{monitors}) or return 0;
    $self->process_osds($cluster->{osdhosts}) or return 0;
    $self->process_mdss($cluster->{mdss}) or return 0;
    return 1;
}

# Do actions after deploying of daemons and global configuration
sub do_post_actions {
    my ($self, $cluster) = @_;
    $self->process_crushmap($cluster->{crushmap}, $cluster->{osdhosts}) or return 0;
    return 1;
}

# Get crushmap and store backup
sub ceph_crush {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(osd crush dump)]) or return 0;
    my $crushdump = decode_json($jstr); #wrong weights, but ignored at this moment
    my $crushdir = $self->{qtmp} . 'crushmap';
    $self->run_ceph_command(['osd', 'getcrushmap', '-o', "$crushdir/crushmap.bin"]);
    $self->run_command(['/usr/bin/crushtool', '-d', "$crushdir/crushmap.bin", '-o', "$crushdir/crushmap"]);
    return $crushdump;
}

# Merge the osd info in the crushmap hierarchy
sub crush_merge {
    my ($self, $buckets, $osdhosts, $devices) = @_;
    foreach my $bucket ( @{$buckets}) {
        my $name = $bucket->{name};
        if ($bucket->{buckets}) {
            # Recurse.

            if (!$self->crush_merge($bucket->{buckets}, $osdhosts, $devices)){
                $self->debug(2, "Failed to merge buckets of $bucket->{name} with osds",
                    "Buckets:", Dumper($bucket->{buckets}));  
                return 0;
            }
        } else {
            if ($bucket->{type} eq 'host') {
                if ($osdhosts->{$name}){
                    my $osds = $osdhosts->{$name}->{osds};
                    $bucket->{buckets} = [];
                    foreach my $osd (sort(keys %{$osds})){
                        my $osdname = $self->get_osd_name($name, $osds->{$osd}->{osd_path});
                        if (!$osdname) {
                            $self->error("Could not find osd name for ", 
                                $osds->{$osd}->{osd_path}, " on $name");
                            return 0;
                        }
                        my $osdb = { 
                            name => $osdname, 
                            # Ceph is rounding the weight
                            weight => int((1000 * $osds->{$osd}->{crush_weight}) + 0.5)/1000.0 , 
                            type => 'osd'
                        };
                        push(@{$bucket->{buckets}}, $osdb);
                        (my $id = $osdname) =~ s/^osd\.//;
                        my $device = { 
                            id => $id, 
                            name => $osdname 
                        };
                        push(@$devices, $device);
                    }
                } else {
                    $self->error("No such hostname in ceph cluster: $name");
                    return 0;
                }    
            }
        }
    }
    return 1;
}

# Escalate the weights that has been set
sub set_weights {
    my ($self, $bucket ) = @_;
    if (!$bucket->{buckets}) {
        if ($bucket->{type} ne 'osd') {
            $self->error('Lowest level of crushmap should be an OSD, but ', $bucket->{name},
                ' has no child buckets and is not an osd!' );
            return;
        }
    } else {
        my $weight = 0.00;
        foreach my $child (@{$bucket->{buckets}}) {
            my $chweight = $self->set_weights($child);
            if (!defined($chweight)) {
                $self->debug(1, "Something went wrong when getting weight of $child->{name}");
                return;
            } 
            $weight += $chweight;
        }
        if (!$bucket->{weight}){
            $bucket->{weight} = $weight;
        } elsif ($weight != $bucket->{weight}) {
            $self->warn("Bucket weight of $bucket->{name} ", 
                "in Quattor differs from the sum of the child buckets! ",
                "Quattor: $bucket->{weight} ", 
                "Sum: $weight");
        }
    }
    return $bucket->{weight};
}

# Makes an one-dimensional array of buckets from a hierarchical one.
# Also fix default attributes (See Quattor schema)
sub flatten_buckets {
    my ($self, $buckets, $flats, $defaults) = @_;
    my $titems = [];
    foreach my $tmpbucket ( @{$buckets}) {
        # First fix attributes
        my $bdefaults;
        if (!$defaults) { # Assume processing top level bucket
            $bdefaults = {
                alg => $tmpbucket->{defaultalg},
                hash => $tmpbucket->{defaulthash},
            };
        } else {
            $bdefaults = $defaults;
        }
        my %bucketh;
        #set default values
        @bucketh{ keys %$bdefaults} = values %$bdefaults;
        # update with tmpbucket
        @bucketh{keys %$tmpbucket} = values %$tmpbucket;
        my $bucket = \%bucketh;
        
        push(@$titems, { name => $bucket->{name}, weight => $bucket->{weight} });
        if ($bucket->{buckets}) {
            my $citems = $self->flatten_buckets($bucket->{buckets}, $flats, $bdefaults);         
            $bucket->{items} = $citems; 
            delete $bucket->{buckets};
        
        }
        if($bucket->{type} ne 'osd'){
            push(@$flats, $bucket);
        }
    }
    return $titems;
}

# Build up the quattor crushmap
sub quat_crush {
    my ($self, $crushmap, $osdhosts) = @_;
    my @newtypes = ();
    my $type_id = 0;
    my ($type_osd, $type_host);
    foreach my $type (@{$crushmap->{types}}) {
        #Must at least contain 'host' and 'osd', because we do the merge on these types.
        if ($type eq 'osd') {
            $type_osd = 1;
        } elsif ($type eq 'host') {
            $type_host = 1;
        } 
        push(@newtypes, { type_id => $type_id, name => $type });
        $type_id +=1;
    }
    if (!$type_osd || !$type_host){
        $self->error("list of types should at least contain 'osd' and 'host'!");
        return 0; 
    }
    $crushmap->{types} = \@newtypes;

    my $devices = [];
    if (!$self->crush_merge($crushmap->{buckets}, $osdhosts, $devices)){
        $self->error("Could not merge the required information into the crushmap");
        return 0;
    }
    my @sorted = sort { $a->{id} <=> $b->{id} } @$devices;
    $crushmap->{devices} = \@sorted;
    foreach my $bucket (@{$crushmap->{buckets}}){
        if (!defined($self->set_weights($bucket))) {
            $self->debug(1, "Something went wrong when setting weight of $bucket->{name}");
            return 0;
        }
    }
    my $newbuckets=[];
    $self->flatten_buckets($crushmap->{buckets}, $newbuckets);
    $crushmap->{buckets} = $newbuckets;

    return $crushmap;
}

# Collect the already used crush ids, all id's should be unique
sub set_used_bucket_id {
    my ($self, $id) = @_;
    if (!$self->{crush_ids}) {
        $self->{crush_ids} = [$id];
    } else {
        if ($id ~~ @{$self->{crush_ids}}) {
            $self->error("ID $id already used in crushmap buckets!");
            return 0;
        } 
        push(@{$self->{crush_ids}}, $id);
    }
    return 1;
}

# Collect the already used ruleset ids, id's can be the same
sub set_used_ruleset_id {
    my ($self, $id) = @_;
    if (!$self->{ruleset_ids}) {
        $self->{ruleset_ids} = [$id];
    } else {
        push(@{$self->{ruleset_ids}}, $id);
    }
    return 1;
}

# Generate an available (not used) ruleset id
# Make sure the used id's are already inserted
sub generate_ruleset_id {
    my ($self) = @_;
    my $newid;
    if (!$self->{ruleset_ids}) { #crushmap from scratch
        $newid = 0;
    } else {
        my $max = max(@{$self->{ruleset_ids}});
        $newid = $max + 1;
    }
    $self->set_used_ruleset_id($newid);
    return $newid;
}

# Generate an available (not used) crush bucket id
# Make sure the used id's are already inserted
sub generate_bucket_id {
    my ($self) = @_;
    my $newid;
    if (!$self->{crush_ids}) { #crushmap from scratch
        $newid = -1;
    } else {
        my $min = min(@{$self->{crush_ids}});
        $newid = $min - 1;
    }
    $self->set_used_bucket_id($newid);
    return $newid;
}

# Compare Crushmap buckets
# Also get ids here
sub cmp_crush_buckets {
    my ($self, $cephbucks, $quatbucks) = @_;
    foreach my $cbuck (@{$cephbucks}) {
        my $found = 0;
        foreach my $qbuck (@{$quatbucks}){
            if ($cbuck->{name} eq $qbuck->{name}){
                if ($cbuck->{type_name} ne $qbuck->{type}) {
                    $self->warn("Type of $cbuck->{name} changed from $cbuck->{type_name} to $qbuck->{type}!");
                }
                if (!$self->set_used_bucket_id($cbuck->{id})) {
                     $self->error("Could not set id of $cbuck->{name}!");
                     return 0;
                }
                $qbuck->{id} = $cbuck->{id};
                $found = 1;
                last;
            }
        } 
        if (!$found) {
            $self->info("Existing ceph bucket $cbuck->{name} removed from quattor crushmap");
        }
    }
    foreach my $qbuck (@{$quatbucks}){
        if (!defined($qbuck->{id})){
            $qbuck->{id} = $self->generate_bucket_id();
            $self->info("Bucket $qbuck->{name} added to crushmap");
        }     
    }
    return 1;
}
        
# Comparing crushmap rules 
# Also get rulesets here
sub cmp_crush_rules {
    my ($self, $cephrules, $quatrules) = @_;
    foreach my $crule (@{$cephrules}) {
        my $found = 0;
        foreach my $qrule (@{$quatrules}){
            if ($crule->{rule_name} eq $qrule->{name}){
                if (defined($qrule->{ruleset})){
                    if ($crule->{ruleset} ne $qrule->{ruleset}) {
                        $self->warn("Ruleset of $qrule->{name} changed",
                            "from $crule->{ruleset} to $qrule->{ruleset}!");
                    }
                } else {
                    $qrule->{ruleset} = $crule->{ruleset};
                }
                $self->set_used_ruleset_id($qrule->{ruleset});
                $found = 1;
                last;
            }
        }
        if (!$found) {
            $self->info("Existing ceph rule $crule->{rule_name} removed from quattor crushmap");
        }
    }
    foreach my $qrule (@{$quatrules}){
        if (!defined($qrule->{ruleset})){
            $qrule->{ruleset} = $self->generate_ruleset_id();
            $self->info("Rule $qrule->{name} added to crushmap");
        }     
    }       
     
    return 1;
}

# Compare the generated crushmap with the installed one
sub cmp_crush {
    my ($self, $cephcr, $quatcr) = @_;
    # Use already existing ids
    # Devices: this should match exactly
    if (!Compare($cephcr->{devices}, $quatcr->{devices})) {
        $self->error("Devices list of Quattor does not match with devices in existing crushmap.");
        return 0;
    }
    # Types
    if (!Compare($cephcr->{types}, $quatcr->{types})) {
        $self->warn("Types are changed in the crushmap!");
    }    
 
    # Buckets
    $self->debug(2, "Comparing crushmap buckets"); 
    $self->cmp_crush_buckets($cephcr->{buckets}, $quatcr->{buckets}) or return 0;
        
    # Rules 
    $self->debug(2, "Comparing crushmap rules"); 
    $self->cmp_crush_rules($cephcr->{rules}, $quatcr->{rules});
     
    return 1;
}

# write out the crushmap and install into cluster
sub write_crush {
    my ($self, $crush) = @_;
    #Use tt files
    my $crushdir = $self->{qtmp} . 'crushmap';
    my $plainfile = "$crushdir/crushmap"; 

    my $fh = CAF::FileWriter->new($plainfile, log => $self, 
                                backup => "." . time() );
    print $fh  "\n";
    $self->debug(5, "Crushmap hash ready to be written to file:", Dumper($crush));
    my $ok = $self->template()->process($CRUSH_TT_FILE, $crush, $fh);
    if (!$ok) {
        $self->error("Unable to render template ", $CRUSH_TT_FILE, ": ",
                     $self->template()->error());
        $fh->cancel();
        $fh->close();
        return 0;
    }
    my $changed = $fh->close();

    if ($changed) {
        # compile and set crushmap    
        if (!$self->run_command(['/usr/bin/crushtool', '-c', "$plainfile", '-o', "$crushdir/crushmap.bin"])){
            $self->error("Could not compile crushmap!");
            return 0;
        }
        if (!$self->run_ceph_command(['osd', 'setcrushmap', '-i', "$crushdir/crushmap.bin"])) {
            $self->error("Could not install crushmap!");
            return 0;
        }
        $self->debug(1, "Changed crushmap installed");
    } else {
        $self->debug(2, "Crushmap not changed");
    }
    return 1;
}   

# Processes the Ceph CRUSHMAP
sub process_crushmap {
    my ($self, $crushmap, $osdhosts) = @_;
    my $cephcr = $self->ceph_crush() or return 0;
    my $quatcr = $self->quat_crush($crushmap, $osdhosts) or return 0;
    $self->cmp_crush($cephcr, $quatcr) or return 0;

    return $self->write_crush($quatcr);
}

#generate mon hosts
sub gen_mon_host {
    my ($self, $cluster) = @_;
    my $config = $cluster->{config};
    $config->{mon_host} = [];
    foreach my $host (@{$config->{mon_initial_members}}) {
        push (@{$config->{mon_host}},$cluster->{monitors}->{$host}->{fqdn});
    }
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
    if ($qceph && ($cephv ne $qceph)) {
        $self->error("Ceph version not corresponding! ",
            "Ceph: $cephv, Quattor: $qceph");
        return 0;
    }        
    if ($qdeploy && ($deplv ne $qdeploy)) {
        $self->error("Ceph-deploy version not corresponding! ",
            "Ceph-deploy: $deplv, Quattor: $qdeploy");
        return 0;
    }
    return 1;
}

sub Configure {
    my ($self, $config) = @_;
    # Get full tree of configuration information for component.
    my $t = $config->getElement($self->prefix())->getTree();
    my $netw = $config->getElement('/system/network')->getTree();
    $self->{cephusr} = $config->getElement('/software/components/accounts/users/ceph')->getTree();
    my $group = $config->getElement('/software/components/accounts/groups/ceph')->getTree();
    $self->{cephusr}->{gid} = $group->{gid};
    $self->{hostname} = $netw->{hostname};
    $self->check_versions($t->{ceph_version}, $t->{deploy_version}) or return 0;
    foreach my $clus (keys %{$t->{clusters}}){
        $self->use_cluster($clus) or return 0;
        my $cluster = $t->{clusters}->{$clus};
        $self->{is_deploy} = $cluster->{deployhosts}->{$self->{hostname}} ? 1 : 0 ;
        $self->gen_mon_host($cluster);
        if (!$self->cluster_ready_check($cluster)) {
            $self->print_man_cmds();
            return 0; 
        }       
        $self->debug(1,"checking configuration");
        $self->check_configuration($cluster) or return 0;
        $self->debug(1,"deploying commands");
        $self->do_deploy() or return 0;
        $self->do_post_actions($cluster) or return 0; 
        $self->print_man_cmds();
        $self->debug(1,'Done');
        return 1;
    }
}


1; # Required for perl module!
