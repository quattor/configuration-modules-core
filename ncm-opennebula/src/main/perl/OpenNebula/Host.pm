#${PMpre} NCM::Component::OpenNebula::Host${PMpost}

=head1 NAME

C<NCM::Component::OpenNebula::Host> adds C<KVM> hosts support to
C<NCM::Component::OpenNebula>.

=head2 Public methods

=over

=item manage_hosts

Adds or removes C<Xen> or C<KVM> hosts.

=cut

sub manage_hosts
{
    my ($self, $one, $type, $resources, %protected) = @_;
    my ($new, $vnm_mad);
    my $hosts = $resources->{hosts};
    my @existhost = $one->get_hosts();
    my %newhosts = map { $_ => 1 } @$hosts;
    my (@rmhosts, @failedhost);

    if (exists($resources->{host_ovs}) and $resources->{host_ovs}) {
        if ($type eq "kvm") {
            $vnm_mad = "ovswitch";
        } elsif ($type eq "xen") {
            $vnm_mad = "ovswitch_brcompat";
        } else {
            $self->error("Host type $type is not supported by Open vSwitch VNM_MAD.");
        }
    } else {
        $vnm_mad = "dummy";
    }

    foreach my $host (@existhost) {
        # Remove the host only if there are no VMs running on it
        if (exists($protected{$host->name})) {
            $self->info("This resource $type is protected and cannot be removed: ", $host->name);
        } elsif (exists($newhosts{$host->name})) {
            $self->debug(1, "We cannot remove this $type host. Is required by Quattor: ", $host->name);
        } elsif ($host->used()) {
            $self->debug(1, "We cannot remove this $type host. There are still running VMs: ", $host->name);
        } else {
            push(@rmhosts, $host->name);
            $host->delete();
        }
    }

    if (@rmhosts) {
        $self->info("Removed $type hosts: ", join(',', @rmhosts));
    }

    foreach my $host (@$hosts) {
        my %host_options = (
            'name'    => $host, 
            'im_mad'  => $type, 
            'vmm_mad' => $type, 
            'vnm_mad' => $vnm_mad
        );
        # to keep the record of our cloud infrastructure
        # we include the host in ONE db even if it fails
        my @hostinstances = $one->get_hosts(qr{^$host$});
        if (scalar(@hostinstances) > 1) {
            $self->error("Found more than one host $host. Only the first host will be modified.");
        }
        my $hostinstance = $hostinstances[0];
        if (exists($protected{$host})) {
            $self->info("This resource $type is protected and cannot be created/updated: $host");
        } elsif ($self->can_connect_to_host($host)) {
            if ($self->enable_node($one, $type, $host, $resources)) {
                if ($hostinstance) {
                    # The host is already available and OK
                    if (!$hostinstance->is_enabled) {
                        $hostinstance->enable;
                        $self->info("Enabled existing host $host");
                    } else {
                        $self->verbose("Host $host is already enabled");
                    };
                } else {
                    # The host is not available yet from ONE framework
                    # and it is running correctly
                    $new = $one->create_host(%host_options);
                    $self->update_something($one, "host", $host, "QUATTOR = 1");
                    $self->info("Created new $type host $host.");
                }
            } else {
                $self->disable_host($one, $type, $host, $hostinstance, %host_options);
            }
        } else {
            push(@failedhost, $host);
            $self->disable_host($one, $type, $host, $hostinstance, %host_options);
        }
    }

    if (@failedhost) {
        $self->error("Detected some error/s including these $type hosts: ", join(', ', @failedhost));
    }

}

=item disable_host

Disables failing OpenNebula C<host>.
This method is called when the C<host> is not reachable from the C<OpenNebula> server.
Always displays a warning message.
In that case the C<host> is disabled in the scheduler.

=cut

sub disable_host
{
    my ($self, $one, $type, $host, $hostinstance, %host_options) = @_;

    $self->warn("Could not connect to $type host: $host.");
    if ($hostinstance) {
        $hostinstance->disable;
        $self->info("Disabled existing host $host");
    } else {
        my $new = $one->create_host(%host_options);
        $new->disable;
        $self->info("Created and disabled new host $host");
    }
}

=item sync_opennebula_hosts

Synchronise hosts C<VMM> scripts.

=cut

sub sync_opennebula_hosts
{
    my ($self) = @_;

    if ($self->run_onehost_as_oneadmin_with_ssh("localhost", 0)) {
        $self->error("Failed to synchronise opennebula hosts.");
    } else {
        $self->verbose("opennebula hosts were synchronised correctly.");
    }
}

=item enable_node

Execute ssh commands required by OpenNebula
also it configures C<Ceph> client if necessary.

=cut

sub enable_node
{
    my ($self, $one, $type, $host, $resources) = @_;

    # Check if we are using Ceph datastores
    if ($self->detect_ceph_datastores($one)) {
        return $self->enable_ceph_node($type, $host, $resources->{datastores});
    }
    # We didn't found a Ceph host configuration
    # no extra tests are required at this point
    # host is ready to be used by the component
    return 1;
}

=pod

=back

=cut

1;
