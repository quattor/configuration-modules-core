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

use Readonly;
Readonly::Scalar my $PATH => '/software/components/${project.artifactId}';

Readonly::Scalar my $RESTART => '/etc/init.d/${project.artifactId} restart';

our $EC=LC::Exception::Context->new->will_store_all;

  # Loop over all of the commands and execute them.  Do this after
  # everything to take care of any dependencies between writing
  # multiple files.
sub run_command {
    my ($self, $command) = @_;
    my $cmd_output = CAF::Process->new($command, log => $self)->output();
    if ( $? ) {
      $self->error("Command failed. Command output: $cmd_output\n");
    } else {
      $self->debug(1,"Command output: $cmd_output\n");
    }
    return ($?, $cmd_output);
}

sub run_ceph_command {
    my ($self, $command) = @_;
    unshift @$command, 'ceph';
    return $self->run_command($command);
}

sub run_ceph_deploy_command {
    my ($self, $command) = @_;
    unshift @$command, 'ceph-deploy';
    return $self->run_command($command);
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
    my $cfg = $t->{'config'};

    # Create the configuration file.

    # Restart the daemon if necessary.
    restart_daemon();
}

1; # Required for perl module!
