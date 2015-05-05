# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::${project.artifactId};

use strict;
use warnings;
use base qw(NCM::Component);

use Readonly;
use NCM::Component::Systemd::Service;

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

Readonly my $BASE => "/software/components/systemd";

=pod

=head2 skip

The C<skip> methods determines what configuration work to skip.
It returns a hashref with key the configuration name and a boolean
value (to skip or not). Undefined configurations will be skipped.

The main purpose for this method is to allow easy subclassing for
replacement components.

=cut

sub skip
{
    my ($self, $config) = @_;
    my $skip = $config->getElement("$BASE/skip")->getTree();
    return $skip;
}

sub Configure
{

    my ($self, $config) = @_;

    my $skip = $self->skip($config);

    if ((! defined($skip->{service})) || $skip->{service}) {
        $self->info("Skipping service configuration");
    } else {
        my $service = NCM::Component::Systemd::Service->new(log => $self);
        $service->configure($config);
    }

    return 1;
}

1; #required for Perl modules
