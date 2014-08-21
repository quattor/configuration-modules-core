# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


package NCM::Component::Ceph::control;

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

sub configure_cluster {
    my ($self, $cluster, $gvalues) = @_;
   
    my ($ceph_conf, $mapping) = $self->get_ceph_conf() or return 0;
    my $quat_conf = $self->get_quat_conf($cluster) or return 0;

    my $structures = $self->compare_conf($ceph_conf, $quat_conf, $mapping, $gvalues) or return 0; #This is the Main function
    
    my $tinies = $self->set_configs($structures->{configs}, $gvalues) or return 0; 
        #Config vanuit file, reverse mapping, krijgen tiny objcs

    $self->deploy_daemons($structures->{deployd}, $tinies, $mapping, $structures->{restartd}) or return 0; #Met change cfg action
    $self->destroy_daemons($structures->{destroyd}, $tinies, $mapping) or return 0;
    #$self->restart_daemons(
    #$self->crush_actions($crushmap, $not_configured) or return 0; #Same as before, but not for new unconfigured hosts
    
    #$self->print_info($restartd, $mand, $not_configured);
    return 1; 
    
}

#get hashes, make one structure of it)
# als config value for global section of the host
# 'missing' value if not available
sub get_ceph_conf {
    my ($self) = @_;
    
    my $master = {};
    my $mapping = { 
        'get_loc' => {}, 
        'get_id' => {}
    };
    $self->osd_hash($master, $mapping) or return ;

    $self->mon_hash($master) or return ;
    $self->mds_hash($master) or return ;
    
    while (my ($hostname, $host) = each(%{$master})) {
        if (!$master->{$hostname}->{fault}){ #only for osd-host, mons should be reachable
            #TODO: Should do testconnection for mons and mdss too (and liefst with fqdns)!
            my $config = $self->pull_host_cfg($hostname) or return ; #TODO>: fqdn?
            $host->{config} = $config->{global};
            while (my ($name, $cfg) = each(%{$config})) {
                if ($name =~ m/^global$/) {
                    $host->{config} = $cfg;           
                } elsif ($name =~ m/^osd\.(\S+)/) {
                    my $loc = $mapping->{get_loc}->{$1};
                    if (!$loc) {
                        $self->error("Could not find location of $name on host $hostname");
                        return ;
                    }
                    $host->{osds}->{$loc}->{config} = $cfg;
                } elsif (($name =~ m/^mon\.(\S+)/) || ($name =~ m/^mon$/)) { #Only one monitor per host..
                    $host->{mon}->{config} = $cfg;
                } elsif (($name =~ m/^mds\.(\S+)/) || ($name =~ m/^mds$/)) { #Only one mds per host..
                    $host->{mds}->{config} = $cfg;
                } else { #TODO implement other section types? e.g. client, radosgw
                    $self->error("Section $name in configfile of host $hostname not yet supported!\n", 
                        "This section will be ignored");
                }
            }  
        }
    }
    return ($master, $mapping);
}

## NEW CFG FUNCTIONS ##
# Pull config from host
sub pull_host_cfg {
    my ($self, $host) = @_; 
    my $pullfile = "$self->{clname}.conf";
    my $hostfile = "$pullfile.$host";
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;

    move($self->{qtmp} . $pullfile, $self->{qtmp} .  $hostfile) or return 0;
    $self->git_commit($self->{qtmp}, $hostfile, "pulled config of host $host"); 
    my $cephcfg = $self->get_host_config($self->{qtmp} . $hostfile) or return 0;

    return $cephcfg;    
}

# Gets the config of the cluster
sub get_host_config {
    my ($self, $file) = @_; 
    my $cephcfg = Config::Tiny->new();
    $cephcfg = Config::Tiny->read($file);
    if (!$cephcfg->{global}) {
        $self->error("Not a valid config file found");
        return 0;
    }   
    return $cephcfg;
}

#TODO: check if host is reachable, combine with ssh-thing? (At this moment same result as before
sub test_host_connection {
    my ($self, $host) = @_;
    
    return 1;
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
    
    if (!$self->test_host_connection($host->{fqdn})) {
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
    } else {#TODO  # Ceph does not show a down ceph mds daemon in his mds map
        my @command = ('start', "mds.$hostname");
        push (@{$structures->{daemon_cmds}}, [@command]);
    }
}


sub compare_mon {
    my ($self, $hostname, $quat_mon, $ceph_mon, $structures) = @_;
   
     
    # check attributes, immutables
    # check config -> changes: add to restart
    my $changecount = $self->compare_config('mon', $hostname, $quat_mon->{config}, $ceph_mon->{config}) or return 0;
    $structures->{configs}->{$hostname}->{mon} = $quat_mon->{config};
    #TODO if ($changecount > 1 && !check_state) {
    if ($changecount > 1) {
        $structures->{restartd}->{$hostname}->{mon} =1;
    }

    return 1;

}

sub compare_mds {
    my ($self, $hostname, $quat_mds, $ceph_mds, $structures) = @_;
    
    my $changecount = $self->compare_config('mds', $hostname, $quat_mds->{config}, $ceph_mds->{config}) or return 0;
    $structures->{configs}->{$hostname}->{mds} = $quat_mds->{config};
    #TODO if ($changecount > 1 && !check_state) {
    if ($changecount > 1) {
        $structures->{restartd}->{$hostname}->{mds} =1;
    }

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
    my $changecount = $self->compare_config('osd', $osdkey, $quat_osd->{config}, $ceph_osd->{config}) or return 0;
    $structures->{configs}->{$hostname}->{osds}->{$osdkey} = $quat_osd->{config}; 
    #TODO if ($changecount > 1 && !check_state) {
    if ($changecount > 1) {
        $structures->{restartd}->{$hostname}->{osds}->{$osdkey} =1;
    } 
    return 1;
}

sub compare_config {
    my ($self, $type, $key, $quat_config, $ceph_config) = @_;
    my $retvalue = 1;
    while (my ($qkey, $qvalue) = each(%{$quat_config})) {
        if (exists $ceph_config->{$qkey}) {
            my $cvalue = $ceph_config->{$qkey};
            if (ref($qvalue) eq 'ARRAY'){
                $qvalue = join(', ',@$qvalue);
            }
            if ($qvalue ne $cvalue) {
            $self->info("$qkey of $type $key changed from $cvalue to $qvalue");
            $retvalue++;
            }
            delete $ceph_config->{$qkey};
        } else {
            $self->info("$qkey with value $qvalue added to config file of $type $key");
            $retvalue++;
        }
    }
    foreach my $ckey (keys %{$ceph_config}) {
        # If we want to keep the existing configuration settings that are not in Quattor,
        # we need to log it here. For now we expect that every used config parameter is in Quattor    
        $self->error("$ckey for $type $key not in quattor");
        return 0;
    }
    return $retvalue;
}


sub compare_host {
    my ($self, $hostname, $quat_host, $ceph_host, $structures) = @_;
    if ($ceph_host->{fault}) {
        # $structures->{ignh}->{$hostname} = $host; For future use ?
        $self->error("Host $hostname is not reachable, and can't be configured at this moment");
        return 0; 
    } else {
        #TODO
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

sub stringify_cfg_arrays {
    my ($self, $cfg) = @_;
    my $config = { %$cfg };
    foreach my $key (%{$config}) {
        if (ref($config->{$key}) eq 'ARRAY'){ #For mon_initial_members
            $config->{$key} = join(', ',@{$config->{$key}});
            $self->debug(3,"Array converted to string:", $config->{$key});
        }
    }
    return $config;
}
 

sub set_host_config {
    my ($self, $hostname, $host, $gvalues) = @_;
    
    my $pushfile = "$self->{clname}.conf";
    my $hostfile = "$pushfile.$host";
    my $cfgfile = $gvalues->{qtmp} . $hostfile;
    
    my $tinycfg = Config::Tiny->new;
    while  (my ($daemon, $config) = each(%{$host})) {
        $tinycfg->{$daemon} = $self->stringify_cfg_arrays($config);
    }

    if (!$tinycfg->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile: $!", "Exitcode: $?"); 
        return 0;
    }   
    $self->debug(2,"content written to config file $cfgfile");
    $self->git_commit($gvalues->{qtmp}, $hostfile, "configfile to push to host $hostname");
    move($cfgfile, $gvalues->{qtmp} .  $pushfile) or return 0;
    $self->push_cfg($hostname, $gvalues->{qtmp}, 1) or return 0;
    
    return $tinycfg;

}


sub set_and_push_configs {
    my ($self, $configs, $mapping, $gvalues) = @_;
    my $tinies = {};
    while  (my ($hostname, $host) = each(%{$configs})) {
        $tinies->{hostname} = $set_host_config($hostname, $host, $gvalues) or return 0;
    }
    return $tinies;
}



1;
