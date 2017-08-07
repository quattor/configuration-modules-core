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
use EDG::WP4::CCM::Path 16.8.0 qw(unescape);
use File::Basename;
use File::Copy qw(copy move);
use JSON::XS;
use Readonly;
use Socket;
use Sys::Hostname;
our $EC=LC::Exception::Context->new->will_store_all;
Readonly my $OSDBASE => qw(/var/lib/ceph/osd/);
Readonly my $JOURNALBASE => qw(/var/lib/ceph/log/);
Readonly::Array my @LS_COMMAND => ('/bin/ls');

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

# Connect to the host to get the osd id, and save it in the map
sub get_and_add_to_mapping {
    my ($self, $hostname, $osd, $mapping) = @_;
    $self->debug(4, "Trying to map $osd->{osd_path} on $osd->{fqdn}");
    my $newosd = $self->get_osd_name($osd->{fqdn}, $osd->{osd_path});
    if (!$newosd) {
        $self->error("Could not retrieve osd name for $osd->{osd_path} on $osd->{fqdn}");
        return;
    }
    $self->add_to_mapping($mapping, $newosd, $hostname, $osd->{osd_path});
    return $newosd;
}

# add osd entries in the mapping hash
sub add_to_mapping {
    my ($self, $mapping, $id, $host, $osd_path) = @_;
    $id =~ s/osd\.//;
    $host =~ s/\..*//;
    my $osdstr = "$host:$osd_path";
    $self->debug(4, "Adding mapping between id $id and $osdstr");
    $mapping->{get_loc}->{$id} = $osdstr;
    $mapping->{get_id}->{$osdstr} = $id;
}

# Get osd name from mapping with location
sub get_name_from_mapping {
    my ($self, $mapping, $host, $osd_path) = @_;
    $host =~ s/\..*//;
    my $osdstr = "$host:$osd_path";
    my $osd_id = $mapping->{get_id}->{$osdstr};
    if (!defined($osd_id)) {
        $self->error("No id found in mapping for $osdstr");
        $self->debug(5, "Mapping:", %{$mapping});
        return;
    }
    return  "osd.$osd_id";
}

# Gets the OSD map
sub osd_hash {
    my ($self, $master, $mapping, $weights, $gvalues) = @_;
    $self->info('Building osd information hash, this can take a while..');
    my $jstr = $self->run_ceph_command([qw(osd dump)]) or return 0;
    my $osddump = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(osd tree)]) or return 0;
    my $osdtree = decode_json($jstr);
    my $hostmap = {};
    foreach my $osd (@{$osddump->{osds}}) {
        my $id = $osd->{osd};
        my ($name,$host);
        $name = "osd.$id";
        foreach my $tosd (@{$osdtree->{nodes}}) {
            if ($tosd->{type} eq 'osd' && $tosd->{id} == $id) {
                $weights->{$name} = $tosd->{crush_weight}; # value displayed in osd dump is not the real value..
                last;
            }
        }
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
        $self->add_to_mapping($mapping, $id, $host, $osdloc);
        my $osdstr = "$host:$osdloc";
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

    my $ph_uuid = $self->run_cat_command_as_ceph_with_ssh(["$osdlink/fsid"], $host);
    if (!$ph_uuid) {
        $self->error("Could not read uuid of osd.$osd. ",
            "If this disk was replaced, please remove from ceph first to reinstall: ",
            "ceph osd crush remove osd.$osd; ceph osd rm osd.$osd; ceph auth del osd.$osd;");
        return ;
    }
    chomp($ph_uuid);
    if ($uuid ne $ph_uuid) {
        $self->error("UUID for osd.$osd of ceph command output differs from that on the disk. ",
            "Ceph value: $uuid, ",
            "Disk value: $ph_uuid");
        return ;
    }
    my $ph_fsid = $self->run_cat_command_as_ceph_with_ssh(["$osdlink/ceph_fsid"], $host);
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
        my $cmd = ['sudo', '/usr/bin/file', '-sL', $loc];
        my $output = $self->run_command_as_ceph_with_ssh($cmd, $host) or return 0;
        if ($output !~ m/^$loc\s*:\s+data\s*$/) {
            $self->error("On host $host: $output", "Expected 'data'");
            return 0;
        }
    } else {
        my $checkmntcmd = ['/bin/findmnt', $loc ];
        if (!$self->run_command_as_ceph_with_ssh($checkmntcmd, $host)) {
            $self->error("OSD path is not a mounted file system on $host:$loc");
            return 0;
        }
        my $mkdircmd = ['sudo', '/bin/mkdir', '-p', $loc];
        $self->run_command_as_ceph_with_ssh($mkdircmd, $host);
        my $lscmd = [@LS_COMMAND, '-1', $loc];
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
    foreach my $mon (@{$monsh->{mons}}){
        $mon->{up} = $mon->{name} ~~ @{$monstate->{quorum_names}};
        my $ip = $self->extract_ip($mon->{addr});
        $mon->{fqdn} = $self->get_host($ip, {}) or return 0;
        $master->{$mon->{name}}->{mon} = $mon; # One monitor per host
        $master->{$mon->{name}}->{fqdn} = $mon->{fqdn};
    }
    return 1;
}

# Gets the MDS map
sub mds_hash {
    my ($self, $master) = @_;
    my $jstr = $self->run_ceph_command([qw(mds stat)]) or return 0;
    my $mdshs = decode_json($jstr);
    foreach my $mds (values %{$mdshs->{mdsmap}->{info}}) {
        my @state = split(':', $mds->{state});
        my $up = ($state[0] eq 'up') ? 1 : 0 ;
        my $mdsp = {
            name => $mds->{name},
            gid => $mds->{gid},
            up => $up
        };
        my $ip = $self->extract_ip($mds->{addr});
        $mdsp->{fqdn} = $self->get_host($ip, {}) or return 0;

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

# does a check on unchangable attributes, returns 0 if different
sub check_immutables {
    my ($self, $name, $imm, $quat, $ceph) = @_;
    my $rc =1;
    foreach my $attr (@{$imm}) {
        # perl complains when doing 'ne' on an undefined value, so:
        if ((defined($quat->{$attr}) xor defined($ceph->{$attr})) ||
            (defined($quat->{$attr}) && ($quat->{$attr} ne $ceph->{$attr})) ){
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
    my ($self, $quat, $ceph) = @_;
    if ($quat->{up} xor $ceph->{up}){
        if ($quat->{up}) {
            return 'start';
        } else {
            return 'stop';
        }
    } else {
        return 0;
    }
}

# Checks which state the daemon should have
sub check_restart {
    my ($self, $hostname, $name, $changes, $qdaemon, $cdaemon, $structures) = @_;
    if (%{$changes} && $qdaemon->{up}){
        $structures->{restartd}->{$hostname}->{$name} = 'restart';
    } elsif ($self->check_state($qdaemon, $cdaemon)) {
        $structures->{restartd}->{$hostname}->{$name} = $self->check_state($qdaemon, $cdaemon);
    }
};

# Do some preparation checks on a new osd
sub prep_osd {
    my ($self,$osd) = @_;

    $self->check_empty($osd->{osd_path}, $osd->{fqdn}) or return 0;
    if ($osd->{journal_path}) {
        (my $journaldir = $osd->{journal_path}) =~ s{/journal$}{};
        $self->check_empty($journaldir, $osd->{fqdn}) or return 0;
    }
    return 1;
}

# Do some preparation checks on a new mds
sub prep_mds {
    my ($self, $hostname, $mds) = @_;
    my $fqdn = $mds->{fqdn};
    my $donecmd = ['test','-e',"/var/lib/ceph/mds/$self->{cluster}-$hostname/done"];
    return $self->run_command_as_ceph_with_ssh($donecmd, $fqdn);
}

# Add the config fields of a new osd to the config file
sub add_osd_to_config {
    my ($self, $hostname, $tinycfg, $osd, $gvalues, $mapping) = @_;
    my $newosd = $self->get_and_add_to_mapping($hostname, $osd, $mapping) or return 0;
    $self->debug(2, "adding new config for $newosd to the configfile");
    $tinycfg->{$newosd} = $self->stringify_cfg_arrays($osd->{config});

    return $self->write_and_push($hostname, $tinycfg, $gvalues);
}

# Puts the osd_objectstore value temporarily in the global section or back out
sub osd_black_magic {
    my ($self, $hostname, $tinycfg, $osd_objectstore, $gvalues) = @_;
    if ($osd_objectstore) {
        $self->debug(2, "Doing osd_objectstore trick with value $osd_objectstore");
        $tinycfg->{global}->{osd_objectstore} = $osd_objectstore;
    } else {
        delete $tinycfg->{global}->{osd_objectstore};
    }
    return $self->write_and_push($hostname, $tinycfg, $gvalues);
}

# Deploys a single daemon
sub deploy_daemon {
    my ($self, $cmd, $name) = @_;
    push (@$cmd, $name);
    $self->debug(1, 'Deploying daemon: ',@$cmd);
    return $self->run_ceph_deploy_command($cmd);
}

# Deploys the new daemons and installs the config file
# if an osd has to have a non default objectstore, this is fixed with a dirty trick here
sub deploy_daemons {
    my ($self, $deployd, $tinies, $gvalues, $mapping) = @_;
    $self->info("Running ceph-deploy commands. This can take some time when adding new daemons. ");
    foreach my $hostname (sort keys(%{$deployd})) {
        my $host = $deployd->{$hostname};
        my $tinycfg = $tinies->{$hostname};
        $self->write_and_push($host->{fqdn}, $tinycfg, $gvalues) or return 0;
        if ($host->{mon}) {
            # deploy mon
            my @command = qw(mon create);
            $self->deploy_daemon(\@command, $host->{mon}->{fqdn}) or return 0;
        }
        if ($host->{osds}) {
            foreach my $osdloc (sort keys(%{$host->{osds}})) {
                my $osd = $host->{osds}->{$osdloc};
                my $foefel;
                if ($osd->{config} && $osd->{config}->{osd_objectstore}) {# pre trick
                    $self->info("deploying new osd with osd_objectstore set, will change global value");
                    $foefel = $tinycfg->{global}->{osd_objectstore};
                    $self->osd_black_magic($hostname, $tinycfg, $osd->{config}->{osd_objectstore}, $gvalues) or return 0;
                }
                my $pathstring = "$osd->{fqdn}:$osd->{osd_path}";
                if ($osd->{journal_path}) {
                    $pathstring = "$pathstring:$osd->{journal_path}";
                }
                my $ret = $self->deploy_daemon([qw(osd create)], $pathstring);
                # create should do a 'prepare'+'activate' according to ceph-deploy help, but it doesn't yet, so..
                $ret = $self->deploy_daemon([qw(osd activate)], $pathstring) if $ret;
                if ($osd->{config} && $osd->{config}->{osd_objectstore}) { # post trick
                    $self->osd_black_magic($hostname, $tinycfg, $foefel, $gvalues) or return 0;
                    $self->info("global value osd_objectstore reverted succesfully");
                }
                return 0 if (!$ret);
                if ($osd->{config}) {
                    $self->add_osd_to_config($hostname, $tinycfg, $osd, $gvalues, $mapping) or return 0;
                } else {
                    $self->get_and_add_to_mapping($hostname, $osd, $mapping) or return 0;
                }
            }
        }
        if ($host->{mds}) {
            # deploy mds
            my @command = qw(mds create);
            $self->deploy_daemon(\@command, "$host->{mds}->{fqdn}:$hostname") or return 0;
        }
    }
    return 1;
}

# Destroys a single daemon (manually command)
sub destroy_daemon {
    my ($self, $type, $name, $cmds) = @_;
    return $self->run_ceph_deploy_command([$type, 'destroy', $name],'','',1);
}

# Destroys daemons that need to be destroyed (Manually at this moment)
sub destroy_daemons {
    my ($self, $destroyd, $mapping) = @_;
    my @cmds = ();
    $self->debug(1, 'Destroying daemons');
    foreach  my $hostname (sort(keys(%{$destroyd}))) {
        foreach  my $type (sort(keys(%{$destroyd->{$hostname}}))) {
            my $daemon = $destroyd->{$hostname}->{$type};
            if ($type eq 'osds') {
                foreach my $osdloc (sort(keys(%{$daemon}))) {
                    my $osdname = $self->get_name_from_mapping($mapping, $hostname, $daemon->{$osdloc}->{osd_path}) or return 0;
                    push(@cmds, $self->destroy_daemon('osd', $osdname));
                }
            } elsif ($type eq 'gtws') {
                foreach my $name (sort(keys(%{$daemon}))) {
                    push(@cmds, $self->destroy_daemon('gtw', $name));
                }
            } elsif ($type ~~ ['mon', 'mds'] )  {
                push(@cmds, $self->destroy_daemon($type, $daemon->{fqdn}));
            } elsif ($type eq 'config') {
                $self->info("Ceph configfile on host $hostname may be removed");
            } else {
                $self->warn("Daemon of unrecognised type $type to be destroyed on host $hostname")
            }
        }
    }
    if(@cmds){
        $self->info("Commands to be run manually:");
        $self->print_cmds(\@cmds);
    }
    return 1;
}
# Restarts daemons that need restart (Manually at this moment)
sub restart_daemons {
    my ($self, $restartd) = @_;
    my @cmds = ();
    $self->debug(1, 'restarting daemons');
    foreach my $hostname (sort(keys(%{$restartd}))) {
        foreach my $name (sort(keys(%{$restartd->{$hostname}}))) {
            push(@cmds, $self->run_command_as_ceph_with_ssh([qw(/sbin/service ceph), $restartd->{$hostname}->{$name}, $name], $hostname, [],1));
        }
    }
    if(@cmds){
        $self->info("Commands to be run manually:");
        $self->print_cmds(\@cmds);
    }
    return 1;
}


1; # Required for perl module!
