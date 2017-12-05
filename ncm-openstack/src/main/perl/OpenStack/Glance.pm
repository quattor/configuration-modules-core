#${PMpre} NCM::Component::OpenStack::Glance${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;


Readonly::Hash my %CONF_FILE => {
    service => "/etc/glance/glance-api.conf",
    registry => "/etc/glance/glance-registry.conf",
};
Readonly::Hash my %DAEMON => {
    service => 'openstack-glance-api',
    registry => 'openstack-glance-registry',
};

=head2 Methods

=over

=item write_config_file

Write the required config files for Glance

=cut

sub write_config_file
{
    my ($self) = @_;

    my $nelement = $self->{element};

    my $changed = 0;
    foreach my $ntype (sort keys %{$self->{tree}}) {
        $self->{element} = $self->{config}->getElement("$self->{elpath}/$ntype");
        # TT file is always common
        $self->{filename} = $CONF_FILE{$ntype};
        $changed += $self->SUPER::write_config_file() ? 1 : 0;
        # And add the required daemons to the list
        push(@{$self->{daemons}}, $DAEMON{$ntype}) if $DAEMON{$ntype};
    }
    return $changed;
}


=pod

=back

=cut

1;
