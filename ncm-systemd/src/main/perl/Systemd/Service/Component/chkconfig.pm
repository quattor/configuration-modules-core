# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::Systemd::Service::Component::chkconfig;

use strict;
use warnings;
use base qw(NCM::Component::${project.artifactId});

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

=pod

=head2 skip

Skip all but service configuration.

=cut

sub skip
{
    my ($self, $config) = @_;
    my $skip = $self->SUPER::skip($config);

    # force override
    foreach my $name (keys %$skip) {
        $skip->{$name} = ($name eq "service") ? 0 : 1;
    } 
    return $skip
}

1; #required for Perl modules
