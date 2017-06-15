#${PMpre} NCM::Component::OpenNebula::Network${PMpost}

=head1 NAME

C<NCM::Component::OpenNebula::Network> adds C<OpenNebula> C<VirtualNetwork> 
configuration support to L<NCM::Component::opennebula>.

=head2 Public methods

=over

=item update_vn_ar

Updates C<VirtualNetwork> C<ARs>.

=cut

sub update_vn_ar
{
    my ($self, $one, $vnetname, $template, $ar, $data) = @_;

    my %ar_opts = ('template' => $template);
    my $arid = $ar->get_ar_id(%ar_opts);
    if (defined($arid)) {
        $self->debug(1, "Detected AR id to update: ", $arid);
        $data->{$vnetname}->{ar}->{ar_id} = "$arid";
        my $templatearid = $self->process_template($data, "vnet");
        $self->debug(1, "AR template to update from $vnetname: $templatearid");
        my $aridup = $ar->updatear($templatearid);
        if (defined($aridup)) {
            $self->info("Updated $vnetname AR id $aridup");
        } else {
            $self->error("Unable to update AR $arid from vnet $vnetname");
        }
    } else {
        $self->debug(2, "Vnet $vnetname AR was not updated");
    }
}

=item get_vnetars

Gets the network C<ARs> (address range) from C<TT> file
and gathers C<VNet> names and IP/MAC addresses.

=cut

sub get_vnetars
{
    my ($self, $config) = @_;
    my $all_ars = $self->process_template_aii($config, "network_ar");
    my %res;

    my @tmp = split(qr{^NETWORK\s+=\s+(?:"|')(\S+)(?:"|')\s*$}m, $all_ars);

    while (my ($ar, $network) = splice(@tmp, 0, 2)) {
        if ($network && $ar) {
            $self->verbose("Detected network AR: $ar within network $network");
            $res{$network}{ar} = $ar;
            $res{$network}{network} = $network;
            $self->debug(3, "This is the network AR template for $network: $ar");
        } else {
            # No ARs found for this VM
            $self->error("No network ARs $ar and/or network info $network.");
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

    foreach my $vnet (sort keys %$arsref) {
        my $ardata = $arsref->{$vnet};
        $self->debug(2, "Testing vnet network AR: $vnet");

        my %ar_opts = ('template' => $ardata->{ar});
        my @exisvnet = $one->get_vnets(qr{^$vnet$});
        foreach my $vnar (@exisvnet) {
            my $arinfo = $vnar->get_ar(%ar_opts);
            if ($remove) {
                $self->remove_duplicate_ars($one, $vnet, $vnar, $arinfo);
                $self->remove_vn_ars($one, $arinfo, $vnet, $ardata, $vnar);
            } else {
                # At this moment it is not possible to update ONE ARs (only leases number)
                # you should remove and recreate the AR/VM if something changes
                if ($arinfo) {
                    $self->remove_duplicate_ars($one, $vnet, $vnar, $arinfo);
                    $self->verbose("vnet: $vnet already contains AR id: ", $arinfo->{AR_ID}->[0]);
                } else {
                    $self->create_vn_ars($one, $vnet, $ardata, $vnar);
                };
            }
       }
    }
}

=item detect_duplicate_ars

Detects duplicate C<VirtualNetwork> C<ARs> with
same IPs or MACs.
Removes duplicated C<ARs> (if C<QUATTOR> flag is set to true).

=cut

sub remove_duplicate_ars
{
    my ($self, $one, $vnet, $vnar, $arinfo) = @_;

    # Try to find different AR ids with the same configuration
    if (defined($arinfo)) {
        my %arpool = $vnar->get_ar_pool();
        my $mac = $arinfo->{MAC}->[0];
        my $ip = $arinfo->{IP}->[0];
        my $arid = $arinfo->{AR_ID}->[0];

        foreach my $id (sort keys %arpool) {
            next if $id == $arid;
            my $msg = '';
            $msg .= "MAC $mac" if $arpool{$id}->{MAC}->[0] eq $mac;
            $msg .= "IP $ip" if $arpool{$id}->{IP}->[0] eq $ip;
            if ($msg) {
                $self->warn("Current AR $arid and $vnet AR $id have the same $msg");
                $self->remove_vn_ars($one, $arpool{$id}, $vnet, $arinfo, $vnar);
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

    # Create a new network AR
    $self->debug(1, "New AR template in $vnet: ", $ardata->{ar});
    my $arid = $ar->addar($ardata->{ar});
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

    # Detect QUATTOR flag and id first
    my $arid = $self->detect_vn_ar_quattor($arinfo) if $arinfo;
    if (defined($arid)) {
        $self->debug(1, "AR template to remove from $vnet: ", $ardata->{ar});
        my $rmid = $ar->rmar($arid);
        if (defined($rmid)) {
            $self->info("Removed from vnet: $vnet AR id: $arid");
        } else {
             $self->error("Unable to remove AR id: $arid from vnet: $vnet");
        }
    } else {
        $self->warn(1, "Unable to remove AR. ",
            "AR is not available or QUATTOR flag is not set vnet: $vnet: ", $ardata->{ar});
    }
}

=item remove_vn_ars

Detects C<Quattor> flag within C<AR> template.

=cut

sub detect_vn_ar_quattor
{
    my ($self, $ar) = @_;
    my $arid = $ar->{AR_ID}->[0];

    if ($ar->{QUATTOR}->[0]) {
        $self->debug(2, "QUATTOR flag found within AR, id: $arid");
        return $arid;
    } else {
        $self->warn("QUATTOR flag not found within AR, id: $arid");
        return;
    }
}

=pod

=back

=cut

1;
