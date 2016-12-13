=head1 NAME

NCM::Component::OpenNebula::Ceph adds C<Ceph> backend support to
L<NCM::Component::OpenNebula:Host>.

=head2 Public methods

=over

=item enable_ceph_node

Configures C<Ceph> client and
it sets the C<Ceph> key in each host.

=cut

use NCM::Component::OpenNebula::commands;


sub enable_ceph_node
{
    my ($self, $type, $host, $datastores) = @_;
    my ($secret, $uuid);
    foreach my $ceph (sort keys %{$datastores}) {
        if ($datastores->{$ceph}->{tm_mad} eq 'ceph') {
            if ($datastores->{$ceph}->{ceph_user_key}) {
                $self->verbose("Found Ceph user key.");
                $secret = $datastores->{$ceph}->{ceph_user_key};
            } else {
                $self->error("Ceph user key not found within Quattor template.");
                return;
            }
            $uuid = $self->set_ceph_secret($type, $host, $datastores->{$ceph}->{ceph_secret});
            return if !$uuid;
            return if !$self->set_ceph_keys($host, $uuid, $secret);
        }
    }
    return 1;
}

=item set_ceph_secret

Sets the C<Ceph> secret to be used by libvirt.

=cut

sub set_ceph_secret
{
    my ($self, $type, $host, $ceph_secret) = @_;
    my $uuid;
    # Add ceph keys as root
    my $cmd = ['secret-define', '--file', $CEPHSECRETFILE];
    my $output = $self->run_virsh_as_oneadmin_with_ssh($cmd, $host);
    if ($output and $output =~ m/^[Ss]ecret\s+(.*?)\s+created$/m) {
        $uuid = $1;
        if ($uuid eq $ceph_secret) {
            $self->verbose("Found Ceph uuid: $uuid to be used by $type host $host.");
        } else {
            $self->error("UUIDs set from datastore and CEPHSECRETFILE $CEPHSECRETFILE do not match.");
            return;
        }
    } else {
        $self->error("Required Ceph UUID not found for $type host $host.");
        return;
    }
    return $uuid;
}

=item set_ceph_keys

Sets the C<Ceph> keys to be used by libvirt.

=cut

sub set_ceph_keys
{
    my ($self, $host, $uuid, $secret) = @_;

    my $cmd = ['secret-set-value', '--secret', $uuid, '--base64', $secret];
    my $output = $self->run_virsh_as_oneadmin_with_ssh($cmd, $host, 1);
    if ($output =~ m/^[sS]ecret\s+value\s+set$/m) {
        $self->info("New Ceph key include into libvirt list: ", $output);
    } else {
        $self->error("Error running virsh secret-set-value command: ", $output);
        return;
    }
    return $output;
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
    $self->info("No Ceph datastores available at this moment.");
    return;
}


=pod

=back

=cut

1;
