# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;
use base qw(NCM::Component);

use NCM::Component::Systemd::Service;

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

sub Configure 
{

    my ($self, $config) = @_;

    my $service = NCM::Component::Systemd::Service->new(log => $self);
    $service->configure($config);

    return 1;
}

1; #required for Perl modules
