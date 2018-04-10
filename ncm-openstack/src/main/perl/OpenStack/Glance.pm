#${PMpre} NCM::Component::OpenStack::Glance${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;


Readonly::Hash my %CONF_FILE => {
    service => "/etc/glance/glance-api.conf",
    registry => "/etc/glance/glance-registry.conf",
};

Readonly::Hash my %DAEMON => {
    service => ['openstack-glance-api'],
    registry => ['openstack-glance-registry'],
};

=head2 Methods

=over

=item _attrs

Override C<filename> attribute (and set C<daemon_map>)

=cut

sub _attrs
{
    my $self = shift;

    $self->{filename} = \%CONF_FILE;
    $self->{daemon_map} = \%DAEMON;
}

=pod

=back

=cut

1;
