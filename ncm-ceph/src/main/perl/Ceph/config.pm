# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


package NCM::Component::Ceph::config;

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
use Data::Dumper;
use Readonly;
use Socket;
our $EC=LC::Exception::Context->new->will_store_all;
# array of non-injectable (not live applicable) configuration settings
Readonly::Array my @NONINJECT => qw(
    mon_host
    mon_initial_members
    fsid
    public_network
    cluster_network
    filestore_xattr_use_omap
    osd_crush_update_on_start
    osd_objectstore
    auth_service_required
    auth_cluster_required
    auth_client_required
);

## Retrieving information of ceph cluster

# Gets the config of the cluster
sub get_host_config {
    my ($self, $file) = @_;
    my $cephcfg = Config::Tiny->new();
    $cephcfg = Config::Tiny->read($file);
    if (!$cephcfg->{global}) {
        $self->warn("Not a valid config file: $file");
    }   
    return $cephcfg;
}

## Processing and comparing between Quattor and Ceph

# Pull config from host
sub pull_host_cfg {
    my ($self, $host, $gvalues) = @_;
    my $pullfile = "$gvalues->{clname}.conf";
    my $hostfile = "$pullfile.$host";
    $self->run_ceph_deploy_command([qw(config pull), $host], $gvalues->{qtmp}, 1) or return ;

    move($gvalues->{qtmp} . $pullfile, $gvalues->{qtmp} .  $hostfile) or return ;
    $self->git_commit($gvalues->{qtmp}, $hostfile, "pulled config of host $host"); 
    my $cephcfg = $self->get_host_config($gvalues->{qtmp} . $hostfile) or return ;

    return $cephcfg;    
}

# Push config to host
sub push_cfg {
    my ($self, $host, $dir, $overwrite) = @_;
    
    $overwrite //= 0;
    $dir //= '';
    
    return $self->run_ceph_deploy_command([qw(admin), $host], $dir, $overwrite);
}

# Makes the changes in the config file realtime by using ceph injectargs
sub inject_realtime {
    my ($self, $host, $changes) = @_;
    my @cmd;
    my @shorthost = split('\.', $host);
    $host = $shorthost[0];
    for my $param (keys %{$changes}) {
        if (!($param ~~ @NONINJECT)) { # Requires Perl > 5.10 !
            @cmd = ('tell',"*.$host",'injectargs','--');
            my $keyvalue = "--$param=$changes->{$param}";
            my $inj = $self->run_ceph_command([@cmd, $keyvalue], 1);
            $self->warn("global setting $keyvalue changed on host $host. Affected daemons should be restarted, ",
                "or the setting needs to be injected: ", $inj);
        } else {
            $self->warn("Non-injectable setting $param changed, affected daemons should be restarted");
        }
    }
    return 1;
}

# Builds the ceph config tree out of the existing config files
sub config_hash {
    my ($self, $master, $mapping, $gvalues) = @_;
    while (my ($hostname, $host) = each(%{$master})) {
        if (!defined($master->{$hostname}->{fault})){ # already done for osd-host
            if (!$self->test_host_connection($master->{$hostname}->{fqdn}, $gvalues)) {
                $master->{$hostname}->{fault} = 1;
            }
        }
        if (!$master->{$hostname}->{fault}) {
            my $config = $self->pull_host_cfg($master->{$hostname}->{fqdn}, $gvalues) ; 
            if (!$config) {
                $self->warn("No valid config file found for host $hostname");
                next;
            }
            $host->{config} = $config->{global};
            while (my ($name, $cfg) = each(%{$config})) {
                if ($name =~ m/^global$/) {
                    $host->{config} = $cfg;    
                } elsif ($name =~ m/^osd\.(\S+)/) {
                    my $loc = $mapping->{get_loc}->{$1};
                    if ($loc) {
                        $host->{osds}->{$loc}->{config} = $cfg;
                    } else {
                        $self->warn("Could not find location of $name on host $hostname, removing from configfile");
                    }
                } elsif ($name =~ m{^mon(\.\S+)?}) { # Only one monitor per host..
                    $host->{mon}->{config} = $cfg;
                } elsif ($name =~ m{^mds(\.\S+)?}) { # Only one mds per host..
                    $host->{mds}->{config} = $cfg;
                } elsif ($name =~ m/^client\.radosgw\.(\S+)/) {
                    $host->{gtws}->{$1}->{config} = $cfg;
                } else {
                    $self->error("Section $name in configfile of host $hostname not yet supported!\n", 
                        "This section will be ignored");
                }
            }
        }
    }
    return 1;   
}

# Looks for arrays in the config and makes strings out of it
sub stringify_cfg_arrays {
    my ($self, $cfg) = @_;
    my $config = { %$cfg };
    foreach my $key (%{$config}) {
        if (ref($config->{$key}) eq 'ARRAY'){ # For mon_initial_members
            $config->{$key} = join(', ',@{$config->{$key}});
            $self->debug(3,"Array converted to string:", $config->{$key});
        }
    }
    return $config;
}

# Push the config to a host
sub write_and_push {
    my ($self, $hostname, $tinycfg, $gvalues) = @_;
    my $pushfile = "$gvalues->{clname}.conf";
    my $hostfile = "$pushfile.$hostname";
    my $cfgfile = $gvalues->{qtmp} . $hostfile;
    $self->debug(5, "Config to write:", Dumper($tinycfg));
    if (!$tinycfg->write($cfgfile)) {
        $self->error("Could not write config file $cfgfile: $!", "Exitcode: $?");
        return 0;
    }
    $self->debug(2,"content written to config file $cfgfile");
    $self->git_commit($gvalues->{qtmp}, $hostfile, "configfile to push to host $hostname");
    move($cfgfile, "$gvalues->{cephusr}->{homeDir}/$pushfile") or return 0;
    $self->push_cfg($hostname, '', 1) or return 0;
}

# Build the Config::Tiny hash for a host 
sub set_host_config {
    my ($self, $hostname, $host, $gvalues) = @_;

    my $tinycfg = Config::Tiny->new;
    while  (my ($daemon, $config) = each(%{$host})) {
        $tinycfg->{$daemon} = $self->stringify_cfg_arrays($config);
    }

    return $tinycfg;

}

# Set the config for each host
sub set_and_push_configs {
    my ($self, $configs, $gvalues) = @_;
    my $tinies = {};
    while  (my ($hostname, $host) = each(%{$configs})) {
        $tinies->{$hostname} = $self->set_host_config($hostname, $host, $gvalues) or return 0;
    }
    return $tinies;
}


1; # Required for perl module!
