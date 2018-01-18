#${PMpre} NCM::Component::OpenStack::Nova${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $NOVA_CONF_FILE => "/etc/nova/nova.conf";

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = [
        'openstack-nova-api',
        'openstack-nova-consoleauth',
        'openstack-nova-scheduler',
        'openstack-nova-conductor',
        'openstack-nova-novncproxy',
    ];
    # Nova has different database parameters
    $self->{db_version} = ["db", "version"];
    $self->{db_sync} = ["db", "sync"];
}

=item pre_populate_service_database

Initializes API, cell and placement databases
for C<Nova> compute service.

=cut

sub pre_populate_service_database
{
    my ($self) = @_;
    my ($cmd, $msg);
    foreach my $method (qw(api_db cell_v2)) {
        if ($method eq 'api_db') {
            $cmd = [$self->{manage}, "$method", qw(sync)];
            $msg = "populate Nova API database";
            $self->_do($cmd, $msg, sensitive => 0) or return;
        } else {
            $cmd = [$self->{manage}, "$method", qw(map_cell0)];
            $msg = "populate Nova placement database";
            $self->_do($cmd, $msg, sensitive => 0) or return;
            $cmd = [$self->{manage}, "$method", qw(create_cell --name=cell1 --verbose)];
            $msg = "populate Nova cell1 database";
            $self->_do($cmd, $msg, sensitive => 0) or return;
        }
    }

    return 1;
}


=pod

=back

=cut

1;
