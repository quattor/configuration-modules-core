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
    $self->{manage} = '';
}

=item post_populate_service_database

Horizon does not need db_sync execution

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
