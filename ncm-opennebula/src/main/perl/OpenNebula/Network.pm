
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

=item get_vnetars

Gets the network C<ARs> (address range) from tt file
and gathers C<VNet> names and IPs/MAC addresses.

=cut

sub get_vnetars
{
    my ($self, $config) = @_;
    my $all_ars = $self->process_template_aii($config, "network_ar");
    my %res;

    my @tmp = split(qr{^NETWORK\s+=\s+(?:"|')(\S+)(?:"|')\s*$}m, $all_ars);

    while (my ($ar,$network) = splice(@tmp, 0 ,2)) {

        if ($network && $ar) {
            $self->verbose("Detected network AR: $ar",
                                     " within network $network");
            $res{$network}{ar} = $ar;
            $res{$network}{network} = $network;
            $self->debug(3, "This is the network AR template for $network: $ar");
        } else {
            # No ars found for this VM
            $self->error("No network ARs and/or network info $ar.");
        };
    }
    return %res;
}

=item remove_and_create_vn_ars

Removes/creates C<ARs> (address range).

=cut

sub remove_and_create_vn_ars
{
    my ($self, $one, $arsref, $remove) = @_;
    my $arid;
    foreach my $vnet (sort keys %{$arsref}) {
        my $ardata = $arsref->{$vnet};
        $self->info ("Testing ONE vnet network AR: $vnet");

        my %ar_opts = ('template' => $ardata->{ar});
        my @exisvnet = $one->get_vnets(qr{^$vnet$});
        foreach my $t (@exisvnet) {
            my $arinfo = $t->get_ar(%ar_opts);
            if ($remove) {
                $self->remove_vn_ars($one, $arinfo, $vnet, $ardata, $t);
            } else {
                $self->create_vn_ars($one, $vnet, $ardata, $t);
            }
       }
    }
}

=item create_vn_ars

Creates C<VirtualNetwork> C<AR> leases.

=cut

sub create_vn_ars
{
    my ($self, $one, $vnet, $ardata, $ar) = @_;
    my $arid;
    # Create a new network AR
    $self->debug(1, "New AR template in $vnet: ", $ardata->{ar});
    $arid = $ar->addar($ardata->{ar});
    if (defined($arid)) {
        $self->info("Created new $vnet AR id: ", $arid);
    } else {
        $self->error("Unable to create new AR within vnet: $vnet");
    }
}

=item remove_vn_ars

Removes <VirtualNetwork> C<AR> leases.

=cut

sub remove_vn_ars
{
    my ($self, $one, $arinfo, $vnet, $ardata, $ar) = @_;
    my $arid;
    # Detect Quattor and id first
    $arid = $self->detect_vn_ar_quattor($arinfo) if $arinfo;
    if (defined($arid)) {
        $self->debug(1, "AR template to remove from $vnet: ", $ardata->{ar});
        my $rmid = $ar->rmar($arid);
        if (defined($rmid)) {
            $self->info("Removed from vnet: $vnet AR id: $arid");
        } else {
             $self->error("Unable to remove AR id: $arid from vnet: $vnet");
        }
    } elsif ($arinfo) {
        $self->error("Quattor flag not found within AR. ",
                             "ONE AII is not allowed to remove this AR.");
    } else {
        $self->debug(1, "Unable to remove AR. ",
                             "AR template is not available from vnet: $vnet: ", $ardata->{ar});
    }
}

=item remove_vn_ars

Detects C<Quattor> flag within C<AR> template.

=cut

sub detect_vn_ar_quattor
{
    my ($self, $ar)  =@_;
    my $arid = $ar->{AR_ID}->[0];

    if ($ar->{QUATTOR}->[0]) {
            $self->info("QUATTOR flag found within AR, id: $arid");
            return $arid;
    } else {
            $self->info("QUATTOR flag not found within AR, id: $arid");
            return;
    }
}

=pod

=back

=cut

1;
