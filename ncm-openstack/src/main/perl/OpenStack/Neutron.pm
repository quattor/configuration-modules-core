#${PMpre} NCM::Component::OpenStack::Neutron${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $NEUTRON_DB_MANAGE_COMMAND => "/usr/bin/neutron-db-manage";
Readonly::Array my @NEUTRON_DB_BOOTSTRAP => qw(--config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head);

Readonly::Hash my %CONF_FILE => {
    service => "/etc/neutron/neutron.conf",
    ml2 => "/etc/neutron/plugins/ml2/ml2_conf.ini",
    linuxbridge => "/etc/neutron/plugins/ml2/linuxbridge_agent.ini",
    l3 => "/etc/neutron/l3_agent.ini",
    dhcp => "/etc/neutron/dhcp_agent.ini",
    metadata => "/etc/neutron/metadata_agent.ini",
};

Readonly::Hash my %DAEMON => {
    service => 'neutron-server',
    linuxbridge => 'neutron-linuxbridge-agent',
    l3 => 'neutron-l3-agent',
    dhcp => 'neutron-dhcp-agent',
    metadata => 'neutron-metadata-agent',
};

Readonly::Hash my %DAEMON_HYPERVISOR => {
    linuxbridge => 'neutron-linuxbridge-agent',
};

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{manage} = $self->{hypervisor} ? undef : $NEUTRON_DB_MANAGE_COMMAND;
    # Neutron has different database parameters
    $self->{db_version} = ["current"];
    $self->{db_sync} = [@NEUTRON_DB_BOOTSTRAP];
}

=item write_config_file

Write the required config files for Neutron

=cut

sub write_config_file
{
    my ($self) = @_;

    my $nelement = $self->{element};

    my %daemon = $self->{hypervisor} ? %DAEMON_HYPERVISOR : %DAEMON;

    my $changed = 0;
    foreach my $ntype (sort keys %{$self->{tree}}) {
        $self->{element} = $self->{config}->getElement("$self->{elpath}/$ntype");
        # TT file is always common
        $self->{filename} = $CONF_FILE{$ntype};
        $changed += $self->SUPER::write_config_file() ? 1 : 0;
        # And add the required daemons to the list
        push(@{$self->{daemons}}, $daemon{$ntype}) if $daemon{$ntype};
    }
    return $changed;
}


=pod

=back

=cut

1;
