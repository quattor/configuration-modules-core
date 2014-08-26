# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


package NCM::Component::Ceph::compare;

use 5.10.1;
use strict;
use warnings;
no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use LC::Exception;
use LC::Find;

use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use Config::Tiny;
use File::Basename;
use File::Path qw(make_path);
use File::Copy qw(copy move);
use Readonly;
use Socket;
our $EC=LC::Exception::Context->new->will_store_all;

#get hashes, make one structure of it)
# als config value for global section of the host
# 'missing' value if not available
sub get_ceph_conf {
    my ($self, $gvalues) = @_;
    
    my $master = {};
    my $mapping = { 
        'get_loc' => {}, 
        'get_id' => {}
    };
    $self->osd_hash($master, $mapping, $gvalues) or return ;

    $self->mon_hash($master) or return ;
    $self->mds_hash($master) or return ;
    
    $self->config_hash( $master, $mapping, $gvalues); 
    return ($master, $mapping);
}

# One big quattor tree
sub get_quat_conf {
    my ($self, $quattor) = @_; 
    my $master = {} ;
    while (my ($hostname, $mon) = each(%{$quattor->{monitors}})) {
        $master->{$hostname}->{mon} = $mon; # Only one monitor
        $master->{$hostname}->{fqdn} = $mon->{fqdn};
    }
    while (my ($hostname, $host) = each(%{$quattor->{osdhosts}})) {
        $master->{$hostname}->{osds} = $self->structure_osds($hostname, $host);
        $master->{$hostname}->{fqdn} = $host->{fqdn};
    }
    while (my ($host, $mds) = each(%{$quattor->{mdss}})) {
        my @fhost = split('\.', $host);# Make sure shortname is used. TODO in schema?
        my $hostname = $fhost[0];
        $master->{$hostname}->{mds} = $mds; # Only one mds
        $master->{$hostname}->{fqdn} = $mds->{fqdn};
    }
    $master->{global} = $quattor->{config}; 
    return $master;
}


sub add_host {
    my ($self, $hostname, $host, $structures) = @_;
    
    if (!$self->test_host_connection($host->{fqdn}, $structures->{gvalues})) {
       $structures->{ignh}->{$hostname} = $host;
       $self->warn("Host $hostname should be added as new, but is not reachable, so it will be ignored");
    } else {
        
        $structures->{configs}->{$hostname}->{global} = $host->{config};
        if ($host->{mon}) {
            $self->add_mon($hostname, $host->{mon}, $structures) or return 0;
        }
        if ($host->{mds}) {
            $self->add_mds($hostname, $host->{mds}, $structures) or return 0;
        }
        while  (my ($osdkey, $osd) = each(%{$host->{osds}})) {
            $self->add_osd($hostname, $osdkey, $osd, $structures) or return 0;
        }
    }
    return 1;
}
sub add_osd { #OSDS should be deployed first to get an ID, and config will be added in deploy fase
    my ($self, $hostname, $osdkey, $osd, $structures) = @_;
    
    $self->prep_osd($osd) or return 0;
    $structures->{deployd}->{$hostname}->{osds}->{$osdkey} = $osd;
}

sub add_mon {
    my ($self, $hostname, $mon, $structures) = @_;

    $structures->{deployd}->{$hostname}->{mon} = $mon;
    $structures->{configs}->{$hostname}->{mon} = $mon->{config};

}

sub add_mds {
    my ($self, $hostname, $mds, $structures) = @_;
    
    if (!$self->prep_mds($hostname, $mds)) { # really not existing
        $structures->{deployd}->{$hostname}->{mds} = $mds;
        $structures->{configs}->{$hostname}->{mds} = $mds->{config};
    } else {  # Ceph does not show a down ceph mds daemon in his mds map
        $structures->{restartd}->{$hostname}->{mds} = 'start';
    }
}

sub compare_mon {
    my ($self, $hostname, $quat_mon, $ceph_mon, $structures) = @_;
   
    if ($ceph_mon->{addr} =~ /^0\.0\.0\.0:0/) { #Initial (unconfigured) member
        return $self->add_mon($hostname, $quat_mon, $structures);
    }
    my $donecmd = ['test','-e',"/var/lib/ceph/mon/$self->{cluster}-$hostname/done"];
    if (!$ceph_mon->{up} && !$self->run_command_as_ceph_with_ssh($donecmd, $quat_mon->{fqdn})) {
        # Node reinstalled without first destroying it
        $self->info("Monitor $hostname shall be reinstalled");
        return $self->add_mon($hostname, $quat_mon, $structures);
    }

    my $changes = $self->compare_config('mon', $hostname, $quat_mon->{config}, $ceph_mon->{config}) or return 0;
    $structures->{configs}->{$hostname}->{mon} = $quat_mon->{config};
    $self->check_restart($hostname, $hostname, $changes,  $quat_mon, $ceph_mon, $structures);
    return 1;

}

sub compare_mds {
    my ($self, $hostname, $quat_mds, $ceph_mds, $structures) = @_;
    
    my $changes = $self->compare_config('mds', $hostname, $quat_mds->{config}, $ceph_mds->{config}) or return 0;
    $structures->{configs}->{$hostname}->{mds} = $quat_mds->{config};
    $self->check_restart($hostname, $hostname, $changes,  $quat_mds, $ceph_mds, $structures);
    return 1;
}

sub compare_osd {
    my ($self, $hostname, $osdkey, $quat_osd, $ceph_osd, $structures) = @_;
    # + osd_objectstore immutable check
    
    my @osdattrs = ();  # special case, journal path is not in 'config' section 
                        # (Should move to 'osd_journal', but would imply schema change)
    if ($quat_osd->{journal_path}) {
        push(@osdattrs, 'journal_path');
    }
    $self->check_immutables($hostname, \@osdattrs, $quat_osd, $ceph_osd) or return 0; 
    
    @osdattrs = ('osd_objectstore');
    $self->check_immutables($hostname, \@osdattrs, $quat_osd->{config}, $ceph_osd->{config}) or return 0;
    my $changes = $self->compare_config('osd', $osdkey, $quat_osd->{config}, $ceph_osd->{config}) or return 0;
    my $osd_id = $structures->{mapping}->{get_id}->{$osdkey} or return 0;
    $structures->{configs}->{$hostname}->{"osd.$osd_id"} = $quat_osd->{config}; 
    $self->check_restart($hostname, "osd.$osd_id", $changes,  $quat_osd, $ceph_osd, $structures);
    return 1;
}

sub compare_config {
    my ($self, $type, $key, $quat_config, $ceph_config) = @_;
    my $cfgchanges = {};
    while (my ($qkey, $qvalue) = each(%{$quat_config})) {
        if (exists $ceph_config->{$qkey}) {
            my $cvalue = $ceph_config->{$qkey};
            if (ref($qvalue) eq 'ARRAY'){
                $qvalue = join(', ',@$qvalue);
            }
            if ($qvalue ne $cvalue) {
            $self->info("$qkey of $type $key changed from $cvalue to $qvalue");
            $cfgchanges->{$qkey} = $qvalue;
            }
            delete $ceph_config->{$qkey};
        } else {
            $self->info("$qkey with value $qvalue added to config file of $type $key");
            $cfgchanges->{$qkey} = $qvalue;
        }
    }
    foreach my $ckey (keys %{$ceph_config}) {
        # If we want to keep the existing configuration settings that are not in Quattor,
        # we need to log it here. For now we expect that every used config parameter is in Quattor    
        $self->error("$ckey for $type $key not in quattor");
        return 0;
    }
    return $cfgchanges;
}

sub compare_global {
    my ($self, $hostname, $quat_config, $ceph_config, $structures) = @_;
    my @attrs = ('fsid');
    $self->check_immutables($hostname, \@attrs, $quat_config, $ceph_config) or return 0;
    my $changes = $self->compare_config('global', $hostname, $quat_config, $ceph_config) or return 0;
    $structures->{configs}->{$hostname}->{global} = $quat_config;
    if (%{$changes}){
        $self->inject_realtime($hostname, $changes) or return 0;
        $structures->{restartd}->{$hostname}->{global} =1;
    }
}
    

sub compare_host {
    my ($self, $hostname, $quat_host, $ceph_host, $structures) = @_;
    if ($ceph_host->{fault}) {
        # $structures->{ignh}->{$hostname} = $host; For future use ?
        $self->error("Host $hostname is not reachable, and can't be configured at this moment");
        return 0; 
    } else {
        $self->compare_global($hostname,  $quat_host->{config}, $ceph_host->{config}, $structures) or return 0;        

        if ($quat_host->{mon} && $ceph_host->{mon}) {
            $self->compare_mon($hostname, $quat_host->{mon}, $ceph_host->{mon}, $structures) or return 0;
        } elsif ($quat_host->{mon}) {
            $self->add_mon($hostname, $quat_host->{mon}, $structures) or return 0;
        } elsif ($ceph_host->{mon}) {
            $structures->{destroy}->{$hostname}->{mon} = $ceph_host->{mon};
        }
        if ($quat_host->{mds} && $ceph_host->{mds}) {
            $self->compare_mds($hostname, $quat_host->{mds}, $ceph_host->{mds}, $structures) or return 0;
        } elsif ($quat_host->{mds}) {
            $self->add_mds($hostname, $quat_host->{mds}, $structures) or return 0;
        } elsif ($ceph_host->{mds}) {
            $structures->{destroy}->{$hostname}->{mds} = $ceph_host->{mds};
        } 
        while  (my ($osdkey, $osd) = each(%{$quat_host->{osds}})) {
            if (exists $ceph_host->{$osdkey}) {
                $self->compare_osd($hostname, $osdkey, $quat_host->{$osdkey},
                    $ceph_host->{$osdkey}, $structures) or return 0;
                delete $ceph_host->{$osdkey};
            } else {
                $self->add_osd($hostname, $osdkey, $osd, $structures) or return 0;
            }
        }
        while  (my ($osdkey, $osd) = each(%{$ceph_host->{osds}})) {
             $structures->{destroy}->{$hostname}->{osds}->{$osdkey} = $osd;
        }
    }
    return 1;
}
    
sub delete_host {#TODO: Remove configfile?
    my ($self, $hostname, $host, $structures) = @_;
    if ($host->{fault}) {
        $structures->{ignh}->{$hostname} = $host;
        $self->warn("Host $hostname should be deleted, but is not reachable, so it will be ignored");
    } else {
        $structures->{destroy}->{$hostname} = $host; # Does the same as destroy on everything
    }
    return 1;
}
    
sub compare_conf {
    my ($self, $ceph_conf, $quat_conf, $mapping, $gvalues) = @_;

    # Compare hosts - add, delete, modify fts
    # Add: push global config, all daemons aan deploylist
    # Delete: NY Impl ( But give commands )
    # Modify : compare all config sections, 
    my $structures = {
        configs  => {},
        deployd  => {},
        destroy  => {},
        daemon_cmds => [], #TODO: restructure this on a host base
        restartd => {},
        ignh => {},
        mandc  => {},
        mapping => $mapping,
        gvalues => $gvalues,
    };
    while  (my ($hostname, $host) = each(%{$quat_conf})) {
        if (exists $ceph_conf->{$hostname}) {
            $self->compare_host($hostname, $quat_conf->{$hostname}, 
                $ceph_conf->{$hostname}, $structures) or return ;
            delete $ceph_conf->{$hostname};
        } else {
            $self->add_host($hostname, $host, $structures) or return ;
        }
    }   
    while  (my ($hostname, $host) = each(%{$ceph_conf})) {
        $self->delete_host($hostname, $host, $structures) or return ;
    }    
    return $structures;
 
}

1;
