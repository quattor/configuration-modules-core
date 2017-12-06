#${PMpre} NCM::Component::OpenNebula::Ceph${PMpost}

use Readonly;
use Data::Dumper;

Readonly our $CEPHSECRETFILE => "/var/lib/one/templates/secret/secret_ceph.xml";

=head1 NAME

C<NCM::Component::OpenNebula::Ceph> adds C<Ceph> backend support to
C<NCM::Component::OpenNebula::Host>.

=head2 Public methods

=over

=item enable_ceph_node

Configures C<Ceph> client and
set the C<Ceph> key in each host.

=cut

sub enable_ceph_node
{
    my ($self, $type, $host, $datastores) = @_;

    foreach my $ceph (sort keys %$datastores) {
        if ($datastores->{$ceph}->{tm_mad} eq 'ceph') {
            my $secret;
            if ($datastores->{$ceph}->{ceph_user_key}) {
                $self->verbose("Found Ceph user key in $ceph datastore");
                $secret = $datastores->{$ceph}->{ceph_user_key};
            } else {
                $self->error("Ceph user key not found within $ceph datastore.");
                return;
            }
            my $uuid = $self->set_ceph_secret($type, $host, $datastores->{$ceph}->{ceph_secret});
            if (!$uuid) {
                $self->error("Not able to set libvirt uuid for $ceph datastore");
                return;
            }
            if (!$self->set_ceph_keys($host, $uuid, $secret)) {
                $self->error("Not able to set ceph libvirt key for $ceph datastore");
                return;
            }
        }
    }
    return 1;
}

=item set_ceph_secret

Sets the C<Ceph> secret to be used by C<libvirt>.

=cut

sub set_ceph_secret
{
    my ($self, $type, $host, $ceph_secret) = @_;

    # Add ceph keys as root
    my $cmd = ['secret-define', '--file', $CEPHSECRETFILE];
    my $output = $self->run_virsh_as_oneadmin_with_ssh($cmd, $host);
    my $uuid;
    if ($output and $output =~ m/^[Ss]ecret\s+(.*?)\s+created$/m) {
        if ($1 eq $ceph_secret) {
            $uuid = $1;
            $self->verbose("Found Ceph uuid $uuid to be used by $type host $host in $CEPHSECRETFILE.");
        } else {
            $self->error("UUIDs set from datastore and CEPHSECRETFILE $CEPHSECRETFILE do not match.");
        }
    } else {
        $self->error("Required Ceph UUID not found for $type host $host.");
    }
    return $uuid;
}

=item set_ceph_keys

Sets the C<Ceph> keys to be used by C<libvirt>.

=cut

sub set_ceph_keys
{
    my ($self, $host, $uuid, $secret) = @_;

    my $cmd = ['secret-set-value', '--secret', $uuid, '--base64', $secret];
    my $output = $self->run_virsh_as_oneadmin_with_ssh($cmd, $host, 1);
    if ($output =~ m/^[sS]ecret\s+value\s+set$/m) {
        $self->info("New Ceph key include into libvirt $host uuid $uuid list: ", $output);
    } else {
        $self->error("Error running virsh secret-set-value command for $host uuid $uuid: ", $output);
        return;
    }
    return 1;
}

=item detect_ceph_datastores

Detects any OpenNebula C<Ceph> datastore setup.

=cut

sub detect_ceph_datastores
{
    my ($self, $one) = @_;
    my @datastores = $one->get_datastores();
    
    foreach my $datastore (@datastores) {
        if ($datastore->{data}->{TM_MAD}->[0] eq "ceph") {
            $self->verbose("Detected Ceph datastore: ", $datastore->name);
            return 1;
        }
    }
    $self->verbose("No Ceph datastores were found");
    return;
}


=pod

=back

=cut

1;
