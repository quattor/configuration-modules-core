#${PMpre} NCM::Component::OpenNebula::VM${PMpost}

=head1 NAME

C<NCM::Component::OpenNebula::VM> adds C<OpenNebula> C<VMs>
manage support to C<NCM::Component::OpenNebula>.

=head2 Public methods

=over

=item get_vmtemplate

Gets C<VM> template from tt file.

=cut

sub get_vmtemplate
{
    my ($self, $config, $oneversion) = @_;

    my $vm_template = $self->process_template_aii($config, "vmtemplate", $oneversion);
    my $vmtemplatename = $1 if ($vm_template =~ m/^NAME\s+=\s+(?:"|')(.*?)(?:"|')\s*$/m);
    my $quattor = $1 if ($vm_template =~ m/^QUATTOR\s+=\s+(.*?)\s*$/m);

    if ($vmtemplatename && $quattor) {
        $self->verbose("The VM template name: $vmtemplatename was generated by QUATTOR.");
    } else {
        # VM template name is mandatory
        $self->error("No VM template name or QUATTOR flag found.");
        return;
    };

    $self->debug(3, "This is vmtemplate $vmtemplatename: $vm_template.");
    return $vm_template
}

=item remove_or_create_vm_template

Creates or removes C<VM> templates
C<$createvmtemplate> flag forces to create
C<$remove> flag forces to remove.

=cut

sub remove_or_create_vm_template
{
    my ($self, $one, $fqdn, $createvmtemplate, $vmtemplate, $permissions, $remove) = @_;

    # Check if the vm template already exists
    my @existtmpls = $one->get_templates(qr{^$fqdn$});

    foreach my $t (@existtmpls) {
        if ($t->{extended_data}->{TEMPLATE}->[0]->{QUATTOR}->[0]) {
            if ($remove) {
                # force to remove
                $self->info("QUATTOR VM template, going to delete: ", $t->name);
                $t->delete();
            } else {
                # Update the current template
                $self->info("QUATTOR VM template, going to update: ", $t->name);
                $self->debug(1, "New $fqdn template : $vmtemplate");
                my $update = $t->update($vmtemplate, 0);
                if ($permissions) {
                    $self->change_permissions($one, "template", $t, $permissions);
                };
                return $update;
            }
        } else {
            $self->info("No QUATTOR flag found for VM template: ", $t->name);
        }
    }

    if ($createvmtemplate && !$remove) {
        my $templ = $one->create_template($vmtemplate);
        $self->debug(1, "New ONE VM template name: ",$templ->name);
        if ($permissions) {
            $self->change_permissions($one, "template", $templ, $permissions);
        };
        return $templ;
    }
}

=item stop_and_remove_one_vms

Stops running C<VMs>.

=cut

sub stop_and_remove_one_vms
{
    my ($self, $one, $fqdn) = @_;
    # Quattor only stops and removes fqdn names
    # running VM names such: fqdn-<ID> are not removed
    my @runningvms = $one->get_vms(qr{^$fqdn$});

    # check if the running $fqdn has QUATTOR = 1
    # if not don't touch it!!
    foreach my $t (@runningvms) {
        if ($t->{extended_data}->{USER_TEMPLATE}->[0]->{QUATTOR}->[0]) {
            $self->info("Running VM will be removed: ",$t->name);
            $t->terminate();
        } else {
            $self->info("No QUATTOR flag found for Running VM: ", $t->name);
        }
    }
}

=pod

=back

=cut

1;
