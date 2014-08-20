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

    my ($configs, $deployd, $restartd, $mand, $not_configured) = 
        $self->compare_conf($ceph_conf, $quat_conf, $gvalues) or return 0; #This is the Main function
    
    my $tinies = $self->set_configs($configs, $mapping) or return 0; 
        #Config vanuit file, reverse mapping, krijgen tiny objcs

    $self->deploy_daemons($deployd, $tinies, $restartd) or return 0; #Met change cfg action

    #$self->crush_actions($crushmap, $not_configured) or return 0; #Same as before, but not for new unconfigured hosts
    
    $self->print_info($restartd, $mand, $not_configured);
    
    
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
                } else { #TODO implement other section types? e.g. radosgw
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
    my $cephcfg = $self->host_config($self->{qtmp} . $hostfile) or return 0;

    return $cephcfg;    
}

# Gets the config of the cluster
sub host_config {
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
        my @fhost = split('\.', $host);
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
        while  (my ($osdkey, $osd) = each(%{$quat_host->{osds}}) {
            $self->add_osd($hostname, $osdkey, $osd, $structure) or return 0;
        }
    }
    return 1;
}
sub add_osd { #OSDS should be deployed first to get an ID
    my ($self, $hostname, $osdkey, $osd, $structure) = @_;
    
    $self->prep_osd($osd) or return 0;
    $structures->{deployd}->{$hostname}->{osds}->{$osdkey} = $osd;
}

sub add_mon {
    my ($self, $hostname, $mon, $structure) = @_;

    $structures->{deployd}->{$hostname}->{mon} = $mon;
    $structures->{configs}->{$hostname}->{mon} = $mon->{config};

}

sub add_mds {
    my ($self, $hostname, $mds, $structure) = @_;
    
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
    return 1;

}

sub compare_mds {
    my ($self, $hostname, $quat_mds, $ceph_mds, $structures) = @_;
#TODO
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
    
    if @osdattrs = ('osd_objectstore');
    $self->check_immutables($hostname, \@osdattrs, $quat_osd->{config}, $ceph_osd->{config}) or return 0;
    
    $self->compare_config($hostname, $osdkey, $quat_osd->{config}, $ceph_osd->{config});
    return 1;
}

sub compare_config {
    my ($self, $hostname, $daemon, $quat_config, $ceph_config) = @_;

    while (my ($qkey, $qvalue) = each(%{$quat_config}) {
        if (exists $ceph_config->{$qkey}) {
            if (ref($qvalue) eq 'ARRAY'){
                $qvalue = join(', ',@$qvalue);
            }
            $self->info("$qkey of $daemon on $hostname changed from $ceph_config->{$qkey} to $qvalue");
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
        while  (my ($osdkey, $osd) = each(%{$quat_host->{osds}}) {
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
    my ($ceph_conf, $quat_conf, $gvalues) = @_;

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
                $ceph_conf->{$hostname}, $structures) or return 0;
            delete $ceph_conf->{$hostname};
        } else {
            $self->add_host($hostname, $host, $structures) or return 0;
        }
    }   
    while  (my ($hostname, $host) = each(%{$ceph_conf})) {
        $self->delete_host($hostname, $host, $structures) or return 0;
    }    
    return 1;
 
}





1;
