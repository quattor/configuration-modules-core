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
    my ($self, $host, $gvalues) = @_;
    my $pullfile = "$gvalues->{clname}.conf";
    my $hostfile = "$pullfile.$host";
    $self->run_ceph_deploy_command([qw(config pull), $host], $gvalues->{qtmp}) or return ;

    move($gvalues->{qtmp} . $pullfile, $gvalues->{qtmp} .  $hostfile) or return ;
    $self->git_commit($gvalues->{qtmp}, $hostfile, "pulled config of host $host"); 
    my $cephcfg = $self->get_host_config($gvalues->{qtmp} . $hostfile) or return ;

    return $cephcfg;    
}

# Push config to host
sub push_cfg {
    my ($self, $host, $overwrite, $dir) = @_;
    
    $overwrite = 0 if (! defined($overwrite));
    $dir = '' if (! defined($dir));
    
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
            $self->info("injecting $keyvalue realtime on $host");
            $self->run_ceph_command([@cmd, $keyvalue]) or return 0;
        } else {
            $self->warn("Non-injectable value $param changed");
        }
    }
    return 1;
}

1; # Required for perl module!
