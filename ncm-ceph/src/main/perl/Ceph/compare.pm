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
use Storable qw(dclone);

our $EC=LC::Exception::Context->new->will_store_all;
Readonly::Hash my %ACTIONS => (
    add => {
        mon => \&add_mon,
        osd => \&add_osd,
        mds => \&add_mds,
        gtw => \&add_gtw,
    },
    compare => {
        mon => \&compare_mon,
        osd => \&compare_osd,
        mds => \&compare_mds,
        gtw => \&compare_gtw,
    }, 
);

# get hashes out of ceph and from the configfiles , make one structure of it
sub get_ceph_conf {
    my ($self, $gvalues) = @_;
   
    $self->debug(2, "Retrieving information from ceph");
    my $master = {};
    my $weights = {};
    my $mapping = { 
        'get_loc' => {}, 
        'get_id' => {}
    };
    $self->osd_hash($master, $mapping, $weights, $gvalues) or return ;

    $self->mon_hash($master) or return ;
    $self->mds_hash($master) or return ;
    
    $self->config_hash( $master, $mapping, $gvalues) or return; 
    $self->debug(5, "Ceph hash:", Dumper($master));
    return ($master, $mapping, $weights);
}

# helper sub to set quattor general and attr config in the hash tree
sub set_host_attrs {
    my ($self, $master, $hostname, $attr, $value, $fqdn, $config) = @_;
    my $hosthashref = $master->{$hostname} ||= {};
    $hosthashref->{$attr} = $value;
    $hosthashref->{fqdn} = $fqdn;
    $hosthashref->{config} = $config;
    $master->{$hostname} = $hosthashref;
}
    
# One big quattor tree on a host base
sub get_quat_conf {
    my ($self, $quattor) = @_; 
    my $master = {} ;
    $self->debug(2, "Building information from quattor");
    if ($quattor->{radosgwh}) {
        while (my ($hostname, $host) = each(%{$quattor->{radosgwh}})) {
            $self->set_host_attrs($master, $hostname, 'gtws', $host->{gateways}, 
                $host->{fqdn}, $quattor->{config});
        }  
    }
    while (my ($hostname, $mon) = each(%{$quattor->{monitors}})) {
        $self->set_host_attrs($master, $hostname, 'mon', $mon, 
            $mon->{fqdn}, $quattor->{config}); # Only one monitor
    }
    while (my ($hostname, $host) = each(%{$quattor->{osdhosts}})) {
        my $osds = $self->structure_osds($hostname, $host);
        $self->set_host_attrs($master, $hostname, 'osds', $osds, 
            $host->{fqdn}, $quattor->{config});
    }
    while (my ($hostname, $mds) = each(%{$quattor->{mdss}})) {
        $hostname =~ s/\..*//;;
        $self->set_host_attrs($master, $hostname, 'mds', $mds, 
            $mds->{fqdn}, $quattor->{config}); # Only one mds
    }
    $self->debug(5, "Quattor hash:", Dumper($master));
    return $master;
}

# Configure a new host
sub add_host {
    my ($self, $hostname, $host, $structures) = @_;
    $self->debug(3, "Configuring new host $hostname");
    if (!$self->test_host_connection($host->{fqdn}, $structures->{gvalues})) {
        $structures->{skip}->{$hostname} = $host;
        $self->warn("Host $hostname should be added as new, but is not reachable, so it will be ignored");
    } else {
        $structures->{configs}->{$hostname}->{global} = $host->{config} if ($host->{config});
        my @uniqs = qw(mon mds);
        foreach my $dtype (@uniqs) {
            if ($host->{$dtype}) {
                $ACTIONS{add}{$dtype}($self, $hostname, $host->{$dtype}, $structures) or return 0;
            }
        }
        my @multiples = qw(osd gtw);
        foreach my $dtype (@multiples) {
            my $dstype = $dtype . "s";
            if ($host->{$dstype}){
                while  (my ($key, $daemon) = each(%{$host->{$dstype}})) {
                    $ACTIONS{add}{$dtype}($self, $hostname, $key, $daemon, $structures) or return 0;
                }
            }
        }
        $structures->{deployd}->{$hostname}->{fqdn} = $host->{fqdn};
    }
    return 1;
}

# Configure a new osd
# OSDS should be deployed first to get an ID, and config will be added in deploy fase
sub add_osd { 
    my ($self, $hostname, $osdkey, $osd, $structures) = @_;
    $self->debug(3, "Configuring new osd $osdkey on $hostname");
    if (!$self->prep_osd($osd)) {
        $self->error("osd $osdkey on $hostname could not be prepared. Osd directory not empty?"); 
        if ($structures->{ok_osd_failures}){
            $structures->{ok_osd_failures}--;
            $osd->{crush_ignore} = 1;
            $self->warn("Ignored one osd prep and deploy failure for $osdkey on $hostname. ", 
                "$structures->{ok_osd_failures} more failures accepted");
            return 1;
        } else {
            return 0;
        }
    }
    $structures->{deployd}->{$hostname}->{osds}->{$osdkey} = $osd;
    return 1;
}

# Configure a new rados gateway
sub add_gtw {
    my ($self, $hostname, $gwname, $gtw, $structures) = @_;
    $self->debug(3, "Configuring new gateway $hostname");
    $structures->{configs}->{$hostname}->{"client.radosgw.$gwname"} = $gtw->{config} if ($gtw->{config});
    return 1;
}

# Configure a new mon
sub add_mon {
    my ($self, $hostname, $mon, $structures) = @_;
    $self->debug(3, "Configuring new mon $hostname");
    $structures->{deployd}->{$hostname}->{mon} = $mon;
    $structures->{configs}->{$hostname}->{mon} = $mon->{config} if ($mon->{config});
    return 1;
}

# Configure a new mds
sub add_mds {
    my ($self, $hostname, $mds, $structures) = @_;
    $self->debug(3, "Configuring new mds $hostname");
    if ($self->prep_mds($hostname, $mds)) { 
        $self->debug(4, "mds $hostname not shown in mds map, but exists.");
        $structures->{restartd}->{$hostname}->{mds} = 'start';
    } else { 
        $structures->{deployd}->{$hostname}->{mds} = $mds;
        $structures->{configs}->{$hostname}->{mds} = $mds->{config} if ($mds->{config});
    }
    return 1;
}

# Compare and change mon config
sub compare_mon {
    my ($self, $hostname, $quat_mon, $ceph_mon, $structures) = @_;
    $self->debug(3, "Comparing mon $hostname");
    if ($ceph_mon->{addr} =~ /^0\.0\.0\.0:0/) { 
        $self->debug(4, "Recreating initial (unconfigured) mon $hostname");
        return $self->add_mon($hostname, $quat_mon, $structures);
    }
    my $donecmd = ['test','-e',"/var/lib/ceph/mon/$self->{cluster}-$hostname/done"];
    if (!$ceph_mon->{up} && !$self->run_command_as_ceph_with_ssh($donecmd, $quat_mon->{fqdn})) {
        # Node reinstalled without first destroying it
        $self->info("Previous mon $hostname shall be reinstalled");
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
    $self->debug(3, "Comparing osd $osdkey on $hostname");
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
    if (!defined($osd_id)) {
        $self->error("Could not map $osdkey to an osd id");
        return 0;
    }
    $self->debug(5, "osd id for $osdkey is $osd_id");
    my $osdname = "osd.$osd_id";
    $structures->{configs}->{$hostname}->{$osdname} = $quat_osd->{config} if ($quat_osd->{config}); 
    $self->check_restart($hostname, $osdname, $changes, $quat_osd, $ceph_osd, $structures);
    return 1;
}

# Compares the values of two given hashes
sub compare_config {
    my ($self, $type, $key, $quat_config, $ceph_config_orig) = @_;
    my $cfgchanges = {};
    my $ceph_config =  dclone($ceph_config_orig) if defined($ceph_config_orig);
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
    if ($ceph_config && %{$ceph_config}) {
        $self->warn("compare_config ".join(", ", keys %{$ceph_config})." for $type $key not in quattor, so removing");
    }
    return $cfgchanges;
}

# Compare the global config
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

# Compare radosgw config
sub compare_gtw {
    my ($self, $hostname, $gwname, $quat_gtw, $ceph_gtw, $structures) = @_;
    $self->debug(3, "Comparing radosgw section of gateway $gwname on $hostname");
    $self->compare_config('radosgw', $gwname, $quat_gtw->{config}, $ceph_gtw->{config});
    $structures->{configs}->{$hostname}->{"client.radosgw.$gwname"} = $quat_gtw->{config} 
        if ($quat_gtw->{config});
}

# Compare different sections of an existing host
sub compare_host {
    my ($self, $hostname, $quat_host, $ceph_host_orig, $structures) = @_;
    $self->debug(3, "Comparing host $hostname");
    my $ceph_host = dclone($ceph_host_orig);
    if ($ceph_host->{fault}) {
        $structures->{skip}->{$hostname} = $quat_host; 
        $self->error("Host $hostname is not reachable, and can't be configured at this moment");
        return 0; 
    } else {
        $structures->{ok_osd_failures} = $structures->{gvalues}->{max_add_osd_failures_per_host};
        $self->compare_global($hostname, $quat_host->{config}, $ceph_host->{config}, $structures) or return 0;
        my @uniqs = qw(mon mds);
        foreach my $dtype (@uniqs) {
            my ($quat_dtype, $ceph_dtype) = ($quat_host->{$dtype}, $ceph_host->{$dtype});
            if ($quat_dtype && $ceph_dtype) {
                $ACTIONS{compare}{$dtype}($self, $hostname, $quat_dtype, $ceph_dtype, $structures) or return 0;
            } elsif ($quat_dtype) {
                $ACTIONS{add}{$dtype}($self, $hostname, $quat_dtype, $structures) or return 0;
            } elsif ($ceph_dtype) {
                $structures->{destroy}->{$hostname}->{$dtype} = $ceph_dtype;
            }
        }
        my @multiples = qw(osd gtw);
        foreach my $dtype (@multiples) {
            my $dstype = $dtype . "s";
            if ($quat_host->{$dstype}) {
                while  (my ($key, $daemon) = each(%{$quat_host->{$dstype}})) {
                    if (exists $ceph_host->{$dstype}->{$key}) {
                        $ACTIONS{compare}{$dtype}($self, $hostname, $key, $daemon,
                            $ceph_host->{$dstype}->{$key}, $structures) or return 0;
                        delete $ceph_host->{$dstype}->{$key};
                    } else {
                        $ACTIONS{add}{$dtype}($self, $hostname, $key, $daemon, $structures) or return 0;
                    }
                }
            }
            if ($ceph_host->{$dstype}) {
                while  (my ($key, $daemon) = each(%{$ceph_host->{$dstype}})) {
                    if ($dtype eq 'osd') { 
                        $structures->{destroy}->{$hostname}->{$dstype}->{$key} = $daemon;
                    } elsif ($dtype eq 'gtw') {
                        $self->info("radosgw config of $key on $hostname not in quattor. Will be removed");   
                    }
                }
            }
        }
        $structures->{deployd}->{$hostname}->{fqdn} = $quat_host->{fqdn};
        delete $structures->{ok_osd_failures};
    }
    return 1;
}

# Remove a host    
sub delete_host {
    my ($self, $hostname, $host, $structures) = @_;
    $self->debug(3, "Removing host $hostname");
    if ($host->{fault}) {
        $structures->{skip}->{$hostname} = $host;
        $self->warn("Host $hostname should be deleted, but is not reachable, so it will be ignored");
    } else {
        $structures->{destroy}->{$hostname} = $host; # Does the same as destroy on everything
    }
    return 1;
}
    
# Compare per host - add, delete, modify 
sub compare_conf {
    my ($self, $quat_conf, $ceph_conf_orig, $mapping, $gvalues) = @_;
    my $ceph_conf =  dclone($ceph_conf_orig) if defined($ceph_conf_orig);
    my $structures = {
        configs  => {},
        deployd  => {},
        destroy  => {},
        restartd => {},
        skip => {},
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
