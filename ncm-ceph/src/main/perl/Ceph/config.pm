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
use Readonly;
use Socket;
our $EC=LC::Exception::Context->new->will_store_all;
# array of non-injectable (not live applicable) configuration settings
Readonly::Array my @NONINJECT => qw(
    mon_host 
    mon_initial_members
    public_network
    filestore_xattr_use_omap
);

## Retrieving information of ceph cluster

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

## Processing and comparing between Quattor and Ceph

# Do a comparison of quattor config and the actual ceph config 
sub cmp_cfgfile {
    my ($self, $type, $quath, $cephh, $cfgchanges) = @_;
    foreach my $qkey (sort(keys %{$quath})) {
        if (exists $cephh->{$qkey}) {
            my $pair = [$quath->{$qkey}, $cephh->{$qkey}];
            #check attrs and reconfigure
            $self->config_cfgfile('change', $qkey, $pair, $cfgchanges) or return 0;
            delete $cephh->{$qkey};
        } else {
            $self->config_cfgfile('add', $qkey, $quath->{$qkey}, $cfgchanges) or return 0;
        }
    }
    foreach my $ckey (keys %{$cephh}) {
        $self->config_cfgfile('del', $ckey, $cephh->{$ckey}, $cfgchanges) or return 0;
    }        
    return 1;
}

# Pull config from host
sub pull_cfg {
    my ($self, $host) = @_;
    my $pullfile = "$self->{clname}.conf";
    my $hostfile = "$pullfile.$host";
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;

    move($self->{qtmp} . $pullfile, $self->{qtmp} .  $hostfile) or return 0;
    $self->git_commit($self->{qtmp}, $hostfile, "pulled config of host $host"); 
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
    my @shorthost = split('\.', $host);
    $host = $shorthost[0];
    for my $param (keys %{$changes}) {
        if (!($param ~~ @NONINJECT)) { # Requires Perl > 5.10 !
            @cmd = ('tell',"*.$host",'injectargs','--');
            my $keyvalue = "--$param=$changes->{$param}";
            $self->info("injecting $keyvalue realtime on $host");
            $self->run_ceph_command([@cmd, $keyvalue]) or return 0;
        } else {
            $self->warn("Non-injectable value $param changed");
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
        my $cfgchanges = {};
        $self->debug(3, "Pulled config:", %$cconf);
        $self->cmp_cfgfile('cfg', $config, $cconf, $cfgchanges) or return 0;
        if (!%{$cfgchanges}) {
            #Config the same, no push needed
            return 1;
        } else {
            $self->inject_realtime($host, $cfgchanges) or return 0;
            $self->push_cfg($host,1) or return 0;
        }
    }    
}
# Prepare the commands to change a global config entry
sub config_cfgfile {
    my ($self,$action,$name,$values, $cfgchanges) = @_;
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
            $values = join(', ',@$values); 
        }
        $cfgchanges->{$name} = $values;

    } elsif ($action eq 'change') {
        my $quat = $values->[0];
        my $ceph = $values->[1];
        if (ref($quat) eq 'ARRAY'){
            $quat = join(', ',@$quat); 
        }
        #TODO: check if changes are valid
        if ($quat ne $ceph) {
            $self->info("$name changed from $ceph to $quat");
            $cfgchanges->{$name} = $quat;
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

#Make all defined hosts ceph admin hosts (=able to run ceph commands)
#This is not (necessary) the same as ceph-deploy hosts!
# Also deploy config file
sub set_admin_host {
    my ($self, $config, $host) = @_;
    $self->pull_compare_push($config, $host) or return 0;
    my @admins=qw(admin);
    push(@admins, $host);
    $self->run_ceph_deploy_command(\@admins,'',1 ) or return 0; 
}

# Do all config actions
sub do_config_actions {
    my ($self, $cluster, $gvalues) = @_;
    my $is_deploy = $gvalues->{is_deploy}; 
    $self->{qtmp} = $gvalues->{qtmp};
    $self->{clname} = $gvalues->{clname};
    my $hosts = $cluster->{allhosts};
    if ($is_deploy) {
        foreach my $host (@{$hosts}) {
            # Set config and make admin host
            $self->set_admin_host($cluster->{config}, $host) or return 0;
        }
    }
    return 1;
}

1; # Required for perl module!
