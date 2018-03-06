#${PMpre} NCM::Component::OpenStack::Nova${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $NOVA_CONF_FILE => "/etc/nova/nova.conf";
Readonly our $NOVA_CEPH_SECRET_FILE => "/var/lib/nova/tmp/secret_ceph.xml";
Readonly our $NOVA_CEPH_COMPUTE_KEYRING => "/etc/ceph/ceph.client.compute.keyring";
Readonly our $VIRSH_COMMAND => "/usr/bin/virsh";
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

=item read_ceph_key

Read Ceph pool key file.

=cut

sub read_ceph_key
{
    my($self) = @_;
    my $key;
    my $fh = CAF::FileReader->new($NOVA_CEPH_COMPUTE_KEYRING, log => $self);
    if (! "$fh") {
        $self->error("Not found Ceph compute keyring file: $NOVA_CEPH_COMPUTE_KEYRING");
        return;
    };
    if ("$fh" =~ m/^(key=.*)/m ) {
        eval {
            $key = $1;
        };
        $key =~ s/key=//s;
        $self->verbose("Found a valid Ceph key in $NOVA_CEPH_COMPUTE_KEYRING");
        return $key;
    } else {
        $self->error("Not found a valid Ceph key in $NOVA_CEPH_COMPUTE_KEYRING");
        return;
    };
}


=item pre_restart

Run before services restart. Used for hypervisors post-configuration.

Must return 1 on success;

=cut

sub pre_restart
{
    my ($self) = @_;
     my ($cmd, $msg);
    # hypervisor Ceph backend post-configuration
    if ($self->{hypervisor} and $self->{tree}->{libvirt}->{rbd_secret_uuid}) {
        my $uuid = $self->{tree}->{libvirt}->{rbd_secret_uuid};

        $cmd = [$VIRSH_COMMAND, "secret-define", "--file", $NOVA_CEPH_SECRET_FILE];
        $msg = "Set virsh Ceph secret file";
        $self->_do($cmd, $msg, sensitive => 0, user => 'root') or return;

        my $key = $self->read_ceph_key();
        $cmd = [$VIRSH_COMMAND, "secret-set-value", "--secret", $uuid, "--base64", $key];
        $msg = "Set virsh Ceph pool key";
        $self->_do($cmd, $msg, sensitive => 1, user => 'root') or return;
    };

    return 1;
}

=pod

=back

=cut

1;
