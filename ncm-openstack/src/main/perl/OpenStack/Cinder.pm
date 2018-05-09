#${PMpre} NCM::Component::OpenStack::Cinder${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our @CINDER_DAEMONS_SERVER => qw(openstack-cinder-api
                                        openstack-cinder-scheduler
                                        openstack-cinder-volume);
Readonly our $CINDER_CEPH_SECRET_FILE => "/var/lib/cinder/tmp/secret_ceph.xml";
Readonly our $CINDER_CEPH_COMPUTE_KEYRING => "/etc/ceph/ceph.client.volumes.keyring";


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = [@CINDER_DAEMONS_SERVER];
    # Cinder does not need any conf file in the hyps
    $self->{tt} = $self->{hypervisor} ? undef : $self->{tt};
    $self->{db_version} = ["db", "version"];
    $self->{db_sync} = ["db", "sync"];
}


=item pre_restart

Run before services restart. Used for hypervisors post-configuration.

Must return 1 on success;

=cut

sub pre_restart
{
    my ($self) = @_;

    # hypervisor Ceph backend post-configuration
    my $uuid = $self->{tree}->{ceph}->{rbd_secret_uuid};
    if ($self->{hypervisor} and $uuid) {
        $self->_libvirt_ceph_secret($CINDER_CEPH_SECRET_FILE, $CINDER_CEPH_COMPUTE_KEYRING, $uuid)
            or return;
    };

    return 1;
}



=pod

=back

=cut

1;
