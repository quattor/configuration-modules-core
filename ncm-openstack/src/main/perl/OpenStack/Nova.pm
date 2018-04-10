#${PMpre} NCM::Component::OpenStack::Nova${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $NOVA_CONF_FILE => "/etc/nova/nova.conf";
Readonly our $NOVA_CEPH_SECRET_FILE => "/var/lib/nova/tmp/secret_ceph.xml";
Readonly our $NOVA_CEPH_COMPUTE_KEYRING => "/etc/ceph/ceph.client.compute.keyring";
Readonly our @NOVA_DAEMONS_SERVER => qw(openstack-nova-api
                                        openstack-nova-consoleauth
                                        openstack-nova-scheduler
                                        openstack-nova-conductor
                                        openstack-nova-novncproxy);
Readonly our @NOVA_DAEMONS_HYPERVISOR => qw(openstack-nova-compute);

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = $self->{hypervisor} ? [@NOVA_DAEMONS_HYPERVISOR] : [@NOVA_DAEMONS_SERVER];
    # Nova has different database parameters
    $self->{manage} = $self->{hypervisor} ? undef : $self->{manage};
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
    foreach my $method (qw(api_db cell_v2)) {
        if ($method eq 'api_db') {
            my $cmd = [$self->{manage}, "$method", qw(sync)];
            $self->_do($cmd, "populate Nova API database", sensitive => 0)
                or return;
        } else {
            my $cmd = [$self->{manage}, "$method", qw(map_cell0)];
            $self->_do($cmd, "populate Nova placement database", sensitive => 0)
                or return;

            $cmd = [$self->{manage}, "$method", qw(create_cell --name=cell1 --verbose)];
            $self->_do($cmd, "populate Nova cell1 database", sensitive => 0)
                or return;
        }
    }

    return 1;
}

=item pre_restart

Run before services restart. Used for hypervisors post-configuration.

Must return 1 on success;

=cut

sub pre_restart
{
    my ($self) = @_;

    # hypervisor Ceph backend post-configuration
    my $uuid = $self->{tree}->{libvirt}->{rbd_secret_uuid};
    if ($self->{hypervisor} and $uuid) {
        $self->_libvirt_ceph_secret($NOVA_CEPH_SECRET_FILE, $NOVA_CEPH_COMPUTE_KEYRING, $uuid)
            or return;
    }

    return 1;
}

=pod

=back

=cut

1;
