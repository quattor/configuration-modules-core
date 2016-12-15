
=head1 NAME

NCM::Component::OpenNebula::Network adds C<OpenNebula> C<VirtualNetwork> 
configuration support to L<NCM::Component::OpenNebula>.

=head2 Public methods

=over


=item update_vn_ar

Updates C<VirtualNetwork> C<ARs>.

=cut

sub update_vn_ar
{
    my ($self, $one, $vnetname, $template, $t, $data) = @_;
    my $arid;

    my %ar_opts = ('template' => $template);
    $arid = $t->get_ar_id(%ar_opts);
    $self->debug(1, "Detected AR id to update: ", $arid);
    if (defined($arid)) {
        $data->{$vnetname}->{ar}->{ar_id} = "$arid";
        $template = $self->process_template($data, "vnet");
        $self->debug(1, "AR template to update from $vnetname: ", $template);
        $arid = $t->updatear($template);
        if (defined($arid)) {
            $self->info("Updated $vnetname AR id: ", $arid);
        } else {
            $self->error("Unable to update AR from vnet: $vnetname");
        }
    }
}

=pod

=back

=cut

1;
