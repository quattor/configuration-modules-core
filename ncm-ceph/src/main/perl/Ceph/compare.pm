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
use Data::Dumper;
use File::Basename;
use File::Path qw(make_path);
use File::Copy qw(copy move);
use Readonly;
use Socket;
our $EC=LC::Exception::Context->new->will_store_all;

# get hashes out of ceph and from the configfiles , make one structure of it
sub get_ceph_conf {
    my ($self, $gvalues) = @_;
   
    $self->debug(2, "Retrieving information from ceph");
    my $master = {};
    my $mapping = { 
        'get_loc' => {}, 
        'get_id' => {}
    };
    $self->osd_hash($master, $mapping, $gvalues) or return ;

    $self->mon_hash($master) or return ;
    $self->mds_hash($master) or return ;
    
    $self->config_hash( $master, $mapping, $gvalues) or return; 
    $self->debug(5, "Ceph hash:", Dumper($master));
    return ($master, $mapping);
}

# One big quattor tree on a host base
sub get_quat_conf {
    my ($self, $quattor) = @_; 
    my $master = {} ;
    $self->debug(2, "Building information from quattor");
    while (my ($hostname, $mon) = each(%{$quattor->{monitors}})) {
        $master->{$hostname}->{mon} = $mon; # Only one monitor
        $master->{$hostname}->{fqdn} = $mon->{fqdn};
        $master->{$hostname}->{config} = $quattor->{config};
    }
    while (my ($hostname, $host) = each(%{$quattor->{osdhosts}})) {
        $master->{$hostname}->{osds} = $self->structure_osds($hostname, $host);
        $master->{$hostname}->{fqdn} = $host->{fqdn};
        $master->{$hostname}->{config} = $quattor->{config};

    }
    while (my ($host, $mds) = each(%{$quattor->{mdss}})) {
        my @fhost = split('\.', $host);# Make sure shortname is used. 
        my $hostname = $fhost[0];
        $master->{$hostname}->{mds} = $mds; # Only one mds
        $master->{$hostname}->{fqdn} = $mds->{fqdn};
        $master->{$hostname}->{config} = $quattor->{config};
    }
    $self->debug(5, "Quattor hash:", Dumper($master));
    return $master;
}

#Configure a new host
sub add_host {
    my ($self, $hostname, $host, $structures) = @_;
    $self->debug(3, "Configuring new host $hostname");
    if (!$self->test_host_connection($host->{fqdn}, $structures->{gvalues})) {
       $structures->{ignh}->{$hostname} = $host;
       $self->warn("Host $hostname should be added as new, but is not reachable, so it will be ignored");
    } else {
        
        $structures->{configs}->{$hostname}->{global} = $host->{config} if ($host->{config});
        if ($host->{mon}) {
            $self->add_mon($hostname, $host->{mon}, $structures) or return 0;
        }
        if ($host->{mds}) {
            $self->add_mds($hostname, $host->{mds}, $structures) or return 0;
        }
        if ($host->{osds}){
            while  (my ($osdkey, $osd) = each(%{$host->{osds}})) {
                $self->add_osd($hostname, $osdkey, $osd, $structures) or return 0;
            }
        }
    }
    return 1;
}

#Configure a new osd
#OSDS should be deployed first to get an ID, and config will be added in deploy fase
sub add_osd { 
    my ($self, $hostname, $osdkey, $osd, $structures) = @_;
    $self->debug(3, "Configuring new osd $osdkey");
    if (!$self->prep_osd($osd)) {
        $self->error("osd $osdkey could not be prepared. Osd directory not empty?"); 
        return 0;
    }
    $structures->{deployd}->{$hostname}->{osds}->{$osdkey} = $osd;
    return 1;
}

#Configure a new mon
sub add_mon {
    my ($self, $hostname, $mon, $structures) = @_;
    $self->debug(3, "Configuring new mon $hostname");
    $structures->{deployd}->{$hostname}->{mon} = $mon;
    $structures->{configs}->{$hostname}->{mon} = $mon->{config} if ($mon->{config});
    return 1;
}

#COnfigure a new mds
sub add_mds {
    my ($self, $hostname, $mds, $structures) = @_;
    $self->debug(3, "Configuring new mds $hostname");
    if (!$self->prep_mds($hostname, $mds)) { # not existing
        $structures->{deployd}->{$hostname}->{mds} = $mds;
        $structures->{configs}->{$hostname}->{mds} = $mds->{config} if ($mds->{config});
    } else {  # Ceph does not show a down ceph mds daemon in his mds map
        $structures->{restartd}->{$hostname}->{mds} = 'start';
    }
    return 1;
}
# Compare and change mon config
sub compare_mon {
    my ($self, $hostname, $quat_mon, $ceph_mon, $structures) = @_;
    $self->debug(3, "Comparing mon $hostname");
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
    $structures->{configs}->{$hostname}->{mon} = $quat_mon->{config} if ($quat_mon->{config});
    $self->check_restart($hostname, 'mon', $changes,  $quat_mon, $ceph_mon, $structures);
    return 1;

}

# Compare and change mds config
sub compare_mds {
    my ($self, $hostname, $quat_mds, $ceph_mds, $structures) = @_;
    $self->debug(3, "Comparing mds $hostname");   
    my $changes = $self->compare_config('mds', $hostname, $quat_mds->{config}, $ceph_mds->{config}) or return 0;
    $structures->{configs}->{$hostname}->{mds} = $quat_mds->{config} if ($quat_mds->{config});
    $self->check_restart($hostname, 'mds', $changes,  $quat_mds, $ceph_mds, $structures);
    return 1;
}

# Compare and change osd config
sub compare_osd {
    my ($self, $hostname, $osdkey, $quat_osd, $ceph_osd, $structures) = @_;
    $self->debug(3, "Comparing osd $osdkey");
    my @osdattrs = ();  # special case, journal path is not in 'config' section 
                        # (Should move to 'osd_journal', but would imply schema change)
    if ($quat_osd->{journal_path}) {
        push(@osdattrs, 'journal_path');
    }
    $self->check_immutables($hostname, \@osdattrs, $quat_osd, $ceph_osd) or return 0; 
    
    @osdattrs = ('osd_objectstore');
    $self->check_immutables($hostname, \@osdattrs, $quat_osd->{config}, $ceph_osd->{config}) or return 0;
    my $changes = $self->compare_config('osd', $osdkey, $quat_osd->{config}, $ceph_osd->{config}) or return 0;
    my $osd_id = $structures->{mapping}->{get_id}->{$osdkey};
    return 0 if (!defined($osd_id));
    $self->debug(5, "osd id for $osdkey is $osd_id");
    my $osdname = "osd.$osd_id";
    $structures->{configs}->{$hostname}->{$osdname} = $quat_osd->{config} if ($quat_osd->{config}); 
    $self->check_restart($hostname, $osdname, $changes,  $quat_osd, $ceph_osd, $structures);
    return 1;
}

# Compares the values of two given hashes
sub compare_config {
    my ($self, $type, $key, $quat_config, $ceph_config) = @_;
    my $cfgchanges = {};
    $self->debug(4, "Comparing config of $type $key");
    $self->debug(5, "Quattor config:", Dumper($quat_config));
    $self->debug(5, "Ceph config:", Dumper($ceph_config));

    while (my ($qkey, $qvalue) = each(%{$quat_config})) {
        if (ref($qvalue) eq 'ARRAY'){
            $qvalue = join(', ',@$qvalue);
        } 
        if (exists $ceph_config->{$qkey}) {
            my $cvalue = $ceph_config->{$qkey};
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
# COmpare the global config
sub compare_global {
    my ($self, $hostname, $quat_config, $ceph_config, $structures) = @_;
    $self->debug(3, "Comparing global section on $hostname");
    my @attrs = ('fsid');
    if ($ceph_config) {
        $self->check_immutables($hostname, \@attrs, $quat_config, $ceph_config) or return 0;
    }
    my $changes = $self->compare_config('global', $hostname, $quat_config, $ceph_config) or return 0;
    $structures->{configs}->{$hostname}->{global} = $quat_config;
    if (%{$changes}){
        $self->inject_realtime($hostname, $changes) or return 0;
    }
    return 1;
}
    
#Compare different sections of an existing host
sub compare_host {
    my ($self, $hostname, $quat_host, $ceph_host, $structures) = @_;
    $self->debug(3, "Comparing host $hostname");
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
        if ($quat_host->{osds}) {
            while  (my ($osdkey, $osd) = each(%{$quat_host->{osds}})) {
                if (exists $ceph_host->{osds}->{$osdkey}) {
                    $self->compare_osd($hostname, $osdkey, $osd,
                        $ceph_host->{osds}->{$osdkey}, $structures) or return 0;
                    delete $ceph_host->{osds}->{$osdkey};
                } else {
                    $self->add_osd($hostname, $osdkey, $osd, $structures) or return 0;
                }
            }
        }
        if ($ceph_host->{osds}) {
            while  (my ($osdkey, $osd) = each(%{$ceph_host->{osds}})) {
                $structures->{destroy}->{$hostname}->{osds}->{$osdkey} = $osd;
            }
        }
    }
    return 1;
}

# Remove a host    
sub delete_host {
    my ($self, $hostname, $host, $structures) = @_;
    $self->debug(3, "Removing host $hostname");
    if ($host->{fault}) {
        $structures->{ignh}->{$hostname} = $host;
        $self->warn("Host $hostname should be deleted, but is not reachable, so it will be ignored");
    } else {
        $structures->{destroy}->{$hostname} = $host; # Does the same as destroy on everything
    }
    return 1;
}
    
# Compare per host - add, delete, modify 
sub compare_conf {
    my ($self, $quat_conf, $ceph_conf, $mapping, $gvalues) = @_;

    # Delete: NY Impl ( But give commands )
    # Modify : compare all config sections, 
    my $structures = {
        configs  => {},
        deployd  => {},
        destroy  => {},
        restartd => {},
        ignh => {},
        mapping => $mapping,
        gvalues => $gvalues,
    };
    $self->debug(2, "Comparing the quattor setup with the running cluster setup");
    while  (my ($hostname, $host) = each(%{$quat_conf})) {
        if (exists($ceph_conf->{$hostname})) {
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
    $self->debug(5, "Structured action hash:", Dumper($structures));
    return $structures;
 
}

1;
