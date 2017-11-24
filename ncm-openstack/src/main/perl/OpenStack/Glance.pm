#${PMpre} NCM::Component::OpenStack::Glance${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $GLANCE_API_CONF_FILE => "/etc/glance/glance-api.conf";
Readonly our $GLANCE_REGISTRY_CONF_FILE => "/etc/glance/glance-registry.conf";

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{filename} = $GLANCE_API_CONF_FILE;
    $self->{daemons} = [
        'openstack-glance-api',
        'openstack-glance-registry',
    ];
}

=item post_populate_service_database

Glance post db_sync execution

=cut

sub post_populate_service_database
{
    my ($self) = @_;
    return 1;
}


=pod

=back

=cut

1;
