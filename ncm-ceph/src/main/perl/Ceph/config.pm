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
    osd_crush_update_on_start
    osd_objectstore
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
    my ($self, $host) = @_;
    my $pullfile = "$self->{clname}.conf";
    my $hostfile = "$pullfile.$host";
    $self->run_ceph_deploy_command([qw(config pull), $host], $self->{qtmp}) or return 0;

    move($self->{qtmp} . $pullfile, $self->{qtmp} .  $hostfile) or return 0;
    $self->git_commit($self->{qtmp}, $hostfile, "pulled config of host $host"); 
    my $cephcfg = $self->get_host_config($self->{qtmp} . $hostfile) or return 0;

    return $cephcfg;    
}

# Push config to host
sub push_cfg {
    my ($self, $host, $overwrite, $dir) = @_;
    
    $overwrite = 0 if (! defined($overwrite));
    $dir = '' if (! defined($dir));
    
    return $self->run_ceph_deploy_command([qw(config push), $host], $dir, $overwrite);
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

#Make all defined hosts ceph admin hosts (=able to run ceph commands)
#This is not (necessary) the same as ceph-deploy hosts!
# Also deploy config file
sub set_admin_host {#MFR
    my ($self, $config, $host) = @_;
    $self->pull_compare_push($config, $host) or return 0;
    my @admins=qw(admin);
    push(@admins, $host);
    $self->run_ceph_deploy_command(\@admins,'',1 ) or return 0; 
}

# Do all config actions
sub do_config_actions {#MFR
    my ($self, $cluster, $gvalues) = @_;
    my $is_deploy = $gvalues->{is_deploy}; 
    $self->{qtmp} = $gvalues->{qtmp};
    $self->{clname} = $gvalues->{clname};
    my $hosts = $cluster->{allhosts};
    if ($is_deploy) {
        foreach my $host (@{$hosts}) {
            if ($gvalues->{key_accept}) {
                $self->ssh_known_keys($host, $gvalues->{key_accept}, $gvalues->{cephusr}->{homeDir});
            }
            # Set config and make admin host
            $self->set_admin_host($cluster->{config}, $host) or return 0;
        }
    }
    return 1;
}

1; # Required for perl module!
