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
    
    $self->set_configs($configs, $mapping) or return 0;

    $self->deploy_daemons($deployd, $restartd) or return 0;

    #$self->crush_actions($crushmap, $not_configured) or return 0;
    
    $self->print_info($restartd, $mand, $not_configured);
    
    
}

#get hashes, make one structure of it)
# als config value for global section of the host
# 'missing' value if not available
sub get_ceph_conf {
    my ($self) = @_;
    
    my $master = [];
    my $mapping = { 
        'get_loc' => {}, 
        'get_id' => {}
    };
    #TODO: geef lijst van hosts uit quattor mee, als dit niet in deze lijst zit, mogen fouten genegeerd worden (=gedelete host), maar wel toegevoegd worden aan $master, voor de commands later 
    $self->osd_hash($master, $mapping);
    $self->mon_hash($master);
    $self->mds_hash($master);
    
    while (my ($hostname, $host) = each(%{$master})) {
        my $config = $self->pull_host_cfg($hostname);
        $host->{config} = $config->{global};
        while (my ($name, $cfg) = each(%{$cephcfg})) {
            if ($name =~ m/^global$/) {
                $host->{config} = $cfg;           
            } elsif ($name =~ m/^osd\.(\S+)/) {
                my $loc = $mapping->{get_loc}->{$1};
                $host->{osds}->{$loc}->{config} = $cfg;
            } elsif ($name =~ m/^mon\.(\S+)/ || ($name =~ m/^mon$/) { #Only one monitor per host..
                $host->{mon}->{config} = $cfg;
            } elsif ($name =~ m/^mds\.(\S+)/ || ($name =~ m/^mds$/) { #Only one mds per host..
                $host->{mds}->{config} = $cfg;
            } else {
                $self->{error} = 
    }
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



sub get_quat_conf {

    
}
