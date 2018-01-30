#${PMpre} NCM::Component::OpenStack::Horizon${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $HORIZON_CONF_FILE => "/etc/openstack-dashboard/local_settings";

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{tt} = 'horizon';
    $self->{filename} = $HORIZON_CONF_FILE;
    $self->{daemons} = ['httpd'];
    $self->{user} = 'apache';
    # Horizon has no database
    delete $self->{manage};
}

=pod

=back

=cut

1;
