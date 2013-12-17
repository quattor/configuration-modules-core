# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;
use LC::Find;
use LC::File qw(copy makedir);

use EDG::WP4::CCM::Element;
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use File::Basename;
use File::Path;
use JSON::XS;

use Readonly;
Readonly::Scalar my $PATH => '/software/components/${project.artifactId}';

Readonly::Scalar my $RESTART => '/etc/init.d/${project.artifactId} restart';

our $EC=LC::Exception::Context->new->will_store_all;

#set the working cluster, (if not given, use the default cluster 'ceph')
sub use_cluster {
    my ($self, $cluster) = @_;
    $cluster ||= 'ceph';
    if ($cluster ne 'ceph') {
        $self->error("Not yet implemented!"); 
        return 0;
    }
    $self->{cluster} = $cluster;
}

# run a command and return the output
sub run_command {
    my ($self, $command) = @_;
    my ($cmd_output, $cmd_err);
    my $cmd = CAF::Process->new($command, log => $self, 
        stdout => \$cmd_output, stderr => \$cmd_err);
    $cmd->execute();
    if ( $? ) {
        $self->error("Command failed. Command output: $cmd_err\n");
        return 0;
    } else {
        $self->debug(1,"Command output: $cmd_output\n");
        if ($cmd_err) {
            $self->warn("Command stderr outputt: $cmd_err\n");
        }    
    }
    return $cmd_output;
}

# run a command prefixed with ceph and return the output in json format
sub run_ceph_command {
    my ($self, $command) = @_;
    unshift @$command, qw(ceph -f json);
    push @$command, ('--cluster', $self->{cluster});
    return $self->run_command($command);
}

# run a command prefixed with ceph-deploy and return the output (no json)
sub run_ceph_deploy_command {
    my ($self, $command) = @_;
    # run as user configured for 'ceph-deploy'
    unshift @$command, qw(ceph-deploy);
    push @$command, ('--cluster', $self->{cluster});
    return $self->run_command($command);
}

# Gets the fsid of the cluster
sub get_fsid {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monhash = decode_json($jstr);
    return $monhash->{fsid}
}

# Gets the OSD map
sub osd_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(osd tree)]) or return 0;
    my $osdtree = decode_json($jstr);
    $jstr = $self->run_ceph_command([qw(osd dump)]) or return 0;
    my $osddump = decode_json($jstr);
# TODO implement
#    my %osdparsed = {};
}
    
# Gets the MON map
sub mon_hash {
    my ($self) = @_;
    my $jstr = $self->run_ceph_command([qw(mon dump)]) or return 0;
    my $monsh = decode_json($jstr);
    my %monparsed = ();
    foreach (@{$monsh->{mons}}){
        my $omon = $_;
        $monparsed{$omon->{name}} = $omon;
    }
    return \%monparsed;
}        
    
# Restart the process.
sub restart_daemon {
    my ($self) = @_;
    CAF::Process->new([qw($RESTART)], log => $self)->run();
    return;
}

sub Configure {
    my ($self, $config) = @_;

    # Get full tree of configuration information for component.
    my $t = $config->getElement($PATH)->getTree();
    foreach my $clus (keys %{$t->{clusters}}){
        $self->use_cluster($clus) or return 0;
        my $cluster = $t->{clusters}->{$clus};
        if ($cluster->{config}->{fsid} ne $self->get_fsid()) {
            return 0;
        }
        
    }
    # Create the configuration file.

    # Restart the daemon if necessary.
    restart_daemon();
}

1; # Required for perl module!
