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
        if (!$master->{$hostname}->{fault}){
            my $config = $self->pull_host_cfg($hostname);
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
        return 1;
    } else {
        # check and add daemons ..
          
    
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
        restartd => {},
        mand  => {},
        ignh => {}
    };
    while  (my ($hostname, $host) = each(%{$quat_conf})) {
        if (exists $ceph_conf->{$hostname}) {
            $self->compare_host($hostname, $quat_conf->{$hostname}, 
                $ceph_conf->{$hostname}, $structures) or return 0;
            delete $ceph_conf->{$hostname};
        } else {
            $self->add_host($hostname, $quat_conf->{$hostname}, $structures) or return 0;
        }
    }   
    while  (my ($hostname, $host) = each(%{$ceph_conf})) {
        $self->delete_host($hostname, $quat_conf->{$hostname}, $structures) or return 0;
    }    
    return 1;
 
}





1;
