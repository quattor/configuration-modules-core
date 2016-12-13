=head1 NAME

NCM::Component::OpenNebula::Host adds C<KVM> hosts support to
L<NCM::Component::OpenNebula>.

=head2 Public methods

=over

=item manage_hosts

Adds or removes C<Xen> or C<KVM> hosts.

=cut

use NCM::Component::OpenNebula::commands;
use NCM::Component::OpenNebula::Ceph;

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
        }
    } else {
        $vnm_mad = "dummy";
    }

    foreach my $t (@existhost) {
        # Remove the host only if there are no VMs running on it
        if (exists($protected{$t->name})) {
            $self->info("This resource $type is protected and can not be removed: ", $t->name);
        } elsif (exists($newhosts{$t->name})) {
            $self->debug(1, "We can't remove this $type host. Is required by Quattor: ", $t->name);
        } elsif ($t->used()) {
            $self->debug(1, "We can't remove this $type host. There are still running VMs: ", $t->name);
        } else {
            push(@rmhosts, $t->name);
            $t->delete();
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
            $self->info("This resource $type is protected and can not be created/updated: $host");
        } elsif ($self->can_connect_to_host($host)) {
            my $output = $self->enable_node($one, $type, $host, $resources);
            if ($output) {
                if ($hostinstance) {
                    # The host is already available and OK
                    $hostinstance->enable if !$hostinstance->is_enabled;
                    $self->info("Enabled existing host $host");
                } else {
                    # The host is not available yet from ONE framework
                    # and it is running correctly
                    $new = $one->create_host(%host_options);
                    $self->update_something($one, "host", $host, "QUATTOR = 1");
                    $self->info("Created new $type host $host.");
                }
            } else {
                $self->
                disable_host($one, $type, $host, $hostinstance, %host_options);
            }
        } else {
            push(@failedhost, $host);
            $self->
            disable_host($one, $type, $host, $hostinstance, %host_options);
        }
    }

    if (@failedhost) {
        $self->error("Detected some error/s including these $type nodes: ", join(', ', @failedhost));
    }

}

=item disable_host

Disables failing OpenNebula C<host>.

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

=item sync_opennebula_hyps

Syncronise hosts C<VMM> scripts.

=cut

sub sync_opennebula_hyps
{
    my ($self) = @_;
    my $output;

    $output = $self->run_onehost_as_oneadmin_with_ssh("localhost", 0);
    if (!$output) {
        $self->error("Quattor unable to execute onehost sync command as oneadmin.");
    } else {
        $self->info("OpenNebula hypervisors were synchronized correctly.");
    }
}

=item enable_node

Executest ssh commands required by OpenNebula
also it configures C<Ceph> client if necessary.

=cut

sub enable_node
{
    my ($self, $one, $type, $host, $resources) = @_;
    my ($output, $cmd, $uuid, $secret);
    # Check if we are using Ceph datastores
    if ($self->detect_ceph_datastores($one)) {
        return $self->enable_ceph_node($type, $host, $resources->{datastores});
    }
    return 1;
}

=pod

=back

=cut

1;
