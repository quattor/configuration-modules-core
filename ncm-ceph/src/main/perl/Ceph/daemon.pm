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

package NCM::Component::Ceph::daemon;

use 5.10.1;
use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use LC::Exception;
use LC::Find;

use Data::Dumper;
use EDG::WP4::CCM::Element qw(unescape);
use File::Basename;
use File::Copy qw(copy move);
use JSON::XS;
use Readonly;
use Socket;
use Sys::Hostname;
our $EC=LC::Exception::Context->new->will_store_all;
Readonly my $OSDBASE => qw(/var/lib/ceph/osd/);
Readonly my $JOURNALBASE => qw(/var/lib/ceph/log/);

# get host of ip; save the map to avoid repetition
sub get_host {
    my ($self, $ip, $hostmap) = @_;
    if (!$hostmap->{$ip}) {
        $hostmap->{$ip} = gethostbyaddr(Socket::inet_aton($ip), Socket::AF_INET());
        if (!$hostmap->{$ip}) {
            $self->error("Parsing commands went wrong: Could not retrieve fqdn of ip $ip.");
            return 0;
        }
        $self->debug(3, "host of $ip is $hostmap->{$ip}");
    }
    return $hostmap->{$ip};
}

sub extract_ip {
    my ($self, $address) = @_;
    my @addr = split(':', $address);
    my $ip = $addr[0];
    return $ip;
}

        
# Gets the OSD map
sub osd_hash {
    my ($self, $master, $mapping, $gvalues) = @_;      
    $self->info('Building osd information hash, this can take a while..');
    my $jstr = $self->run_ceph_command([qw(osd dump)]) or return 0;
    my $osddump = decode_json($jstr);  
    my %osdparsed = ();
    my $hostmap = {};
    foreach my $osd (@{$osddump->{osds}}) {
        my $id = $osd->{osd};
        my ($name,$host);
        $name = "osd.$id";
        my $ip = $self->extract_ip($osd->{public_addr});
        if (!$ip) {
            $self->error("IP of osd osd.$id not set or misconfigured!");
            return 0;
        }
        my $fqdn = $self->get_host($ip, $hostmap) or return 0;
        
        my @fhost = split('\.', $fqdn);
        $host = $fhost[0];
        
        # If host is unreachable, go on with empty one. Process this later 
        if (!defined($master->{$host}->{fault})) {
            if (!$self->test_host_connection($fqdn, $gvalues)) {
                $master->{$host}->{fault} = 1;
                $self->warn("Could not retrieve necessary information from host $host");
            } else {
                $master->{$host}->{fault} = 0;
            }
            $master->{$host}->{fqdn} = $fqdn;
        } 
        next if $master->{$host}->{fault};
            
        my ($osdloc, $journalloc) = $self->get_osd_location($id, $fqdn, $osd->{uuid}) or return 0;
        
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
        $mapping->{get_loc}->{$id} = $osdstr;
        $mapping->{get_id}->{$host}->{$osdloc} = $id;
        $master->{$host}->{osds}->{$osdstr} = $osdp;
    }
    return 1;
}

# checks whoami,fsid and ceph_fsid and returns the real path
sub get_osd_location {
    my ($self,$osd, $host, $uuid) = @_;
    my $osdlink = "/var/lib/ceph/osd/$self->{cluster}-$osd";
    if (!$host) {
        $self->error("Can not find osd without a hostname");
        return ;
    }   
    
    my @catcmd = ('/usr/bin/cat');
    my $ph_uuid = $self->run_command_as_ceph_with_ssh([@catcmd, $osdlink . '/fsid'], $host);
    chomp($ph_uuid);
    if ($uuid ne $ph_uuid) {
        $self->error("UUID for osd.$osd of ceph command output differs from that on the disk. ",
            "Ceph value: $uuid, ", 
            "Disk value: $ph_uuid");
        return ;    
    }
    my $ph_fsid = $self->run_command_as_ceph_with_ssh([@catcmd, $osdlink . '/ceph_fsid'], $host);
    chomp($ph_fsid);
    my $fsid = $self->{fsid};
    if ($ph_fsid ne $fsid) {
        $self->error("fsid for osd.$osd not matching with this cluster! ", 
            "Cluster value: $fsid, ", 
            "Disk value: $ph_fsid");
        return ;
    }
    my @loccmd = ('/bin/readlink');
    my $osdloc = $self->run_command_as_ceph_with_ssh([@loccmd, $osdlink], $host);
    my $journalloc = $self->run_command_as_ceph_with_ssh([@loccmd, '-f', "$osdlink/journal"], $host);
    chomp($osdloc);
    chomp($journalloc);
    return $osdloc, $journalloc;

}

# If directory is given, checks if the directory is empty
# If raw device is given, check for existing file systems
sub check_empty {
    my ($self, $loc, $host) = @_;
    if ($loc =~ m{^/dev/}){
        my $cmd = ['sudo', '/usr/bin/file', '-s', $loc];
        my $output = $self->run_command_as_ceph_with_ssh($cmd, $host) or return 0;
        if ($output !~ m/^$loc\s*:\s+data\s*$/) { 
            $self->error("On host $host: $output", "Expected 'data'");
            return 0;
        }
    } else {
        my $mkdircmd = ['sudo', '/bin/mkdir', '-p', $loc];
        $self->run_command_as_ceph_with_ssh($mkdircmd, $host); 
        my $lscmd = ['/usr/bin/ls', '-1', $loc];
        my $lsoutput = $self->run_command_as_ceph_with_ssh($lscmd, $host) or return 0;
        my $lines = $lsoutput =~ tr/\n//;
        if ($lines) {
            $self->error("$loc on $host is not empty!");
            return 0;
        } 
    }
    return 1;    
}

# Gets the MON map
sub mon_hash {
    my ($self, $master) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monsh = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(quorum_status)]) or return 0;
    my $monstate = decode_json($jstr);
    my %monparsed = ();
    my $hostmap = {};
    foreach my $mon (@{$monsh->{mons}}){
        $mon->{up} = $mon->{name} ~~ @{$monstate->{quorum_names}};
        my $ip = $self->extract_ip($mon->{addr});
        $mon->{fqdn} = $self->get_host($ip, $hostmap) or return 0;
        $monparsed{$mon->{name}} = $mon; 
        $master->{$mon->{name}}->{mon} = $mon; #One monitor per host
        $master->{$mon->{name}}->{fqdn} = $mon->{fqdn};
    }
    return 1;
}

# Gets the MDS map 
sub mds_hash {
    my ($self, $master) = @_;
    my $jstr = $self->run_ceph_command([qw(mds stat)]) or return 0;
    my $mdshs = decode_json($jstr);
    my %mdsparsed = ();
    my $hostmap = {};
    foreach my $mds (values %{$mdshs->{mdsmap}->{info}}) {
        my @state = split(':', $mds->{state});
        my $up = ($state[0] eq 'up') ? 1 : 0 ;
        my $mdsp = {
            name => $mds->{name},
            gid => $mds->{gid},
            up => $up
        };
        $mdsparsed{$mds->{name}} = $mdsp;
        my $ip = $self->extract_ip($mds->{addr});
        $mdsp->{fqdn} = $self->get_host($ip, $hostmap) or return 0;
        
        # For daemons rolled out with old version of ncm-ceph
        my @fhost = split('\.', $mds->{name});
        my $host = $fhost[0];
        $master->{$host}->{mds} = $mdsp;
        $master->{$host}->{fqdn} = $mdsp->{fqdn};
    }
    return 1;
}       

# Converts a host/osd hierarchy in a 'host:osd' structure
sub structure_osds {
    my ($self, $hostname, $host) = @_; 
    my $osds = $host->{osds};
    my %flat = (); 
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
        my $osdstr = "$hostname:$osdpath";
        $flat{$osdstr} = $newosd;
    }   
    return \%flat;

}

#does a check on unchangable attributes, returns 0 if different
sub check_immutables {
    my ($self, $name, $imm, $quat, $ceph) = @_;
    my $rc =1;
    foreach my $attr (@{$imm}) {
        if ((defined($quat->{$attr}) || defined($ceph->{$attr})) && 
            ($quat->{$attr} ne $ceph->{$attr}) ){
            $self->error("Attribute $attr of $name not corresponding.", 
                "Quattor: $quat->{$attr}, ",
                "Ceph: $ceph->{$attr}");
            $rc=0;
        }
    }
    return $rc;
}
# Checks and changes the state on the host
sub check_state {#TODO MFC
    my ($self, $id, $host, $type, $quat, $ceph, $cmdh) = @_;
    if ($quat->{up} xor $ceph->{up}){
        my @command; 
        if ($quat->{up}) {
            @command = qw(start); 
        } else {
            @command = qw(stop);
        }
        push (@command, "$type.$id");
        push (@{$cmdh->{daemon_cmds}}, [@command]);
    }
}

sub prep_osd { 
    my ($self,$osd) = @_;
    
    $self->check_empty($osd->{osd_path}, $osd->{fqdn}) or return 0;
    if ($osd->{journal_path}) {
        (my $journaldir = $osd->{journal_path}) =~ s{/journal$}{};
        $self->check_empty($journaldir, $osd->{fqdn}) or return 0;
    }
}

sub prep_mds { 
    my ($self, $hostname, $mds) = @_;
        my $fqdn = $mds->{fqdn};
        my $donecmd = ['test','-e',"/var/lib/ceph/mds/$self->{cluster}-$hostname/done"];
        return $self->run_command_as_ceph_with_ssh($donecmd, $fqdn);
}

# Deploy daemons #TODO
sub do_deploy {#MFO
    my ($self, $is_deploy, $cmdh) = @_;
    while (my $cmd = shift @{$cmdh->{daemon_cmds}}) {
        $self->debug(1,"Daemon command:", @$cmd);
        $self->run_daemon_command($cmd) or return 0;
    }
    $self->print_cmds($cmdh->{man_cmds});
    return 1;
}

1; # Required for perl module!
