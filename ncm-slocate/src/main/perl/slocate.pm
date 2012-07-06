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
