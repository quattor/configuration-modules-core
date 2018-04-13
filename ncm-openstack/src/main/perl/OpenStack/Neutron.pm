#${PMpre} NCM::Component::OpenStack::Neutron${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $NEUTRON_DB_MANAGE_COMMAND => "/usr/bin/neutron-db-manage";
Readonly::Array my @NEUTRON_DB_BOOTSTRAP => qw(--config-file /etc/neutron/neutron.conf
    --config-file /etc/neutron/plugins/ml2/ml2_conf.ini
    upgrade head);

Readonly::Hash my %CONF_FILE => {
    service => "/etc/neutron/neutron.conf",
    ml2 => "/etc/neutron/plugins/ml2/ml2_conf.ini",
    linuxbridge => "/etc/neutron/plugins/ml2/linuxbridge_agent.ini",
    openvswitch => "/etc/neutron/plugins/ml2/openvswitch_agent.ini",
    l3 => "/etc/neutron/l3_agent.ini",
    dhcp => "/etc/neutron/dhcp_agent.ini",
    metadata => "/etc/neutron/metadata_agent.ini",
};

Readonly::Hash my %DAEMON => {
    service => ['neutron-server'],
    linuxbridge => ['neutron-linuxbridge-agent'],
    openvswitch => ['neutron-openvswitch-agent'],
    l3 => ['neutron-l3-agent'],
    dhcp => ['neutron-dhcp-agent'],
    metadata => ['neutron-metadata-agent'],
};

Readonly::Hash my %DAEMON_HYPERVISOR => {
    linuxbridge => ['neutron-linuxbridge-agent'],
    openvswitch => ['neutron-openvswitch-agent'],
};

=head2 Methods

=over

=item _attrs

Override C<manage>, C<db> and C<filename> attribute (and set C<daemon_map>)

=cut

sub _attrs
{
    my $self = shift;

    $self->{manage} = $self->{hypervisor} ? undef : $NEUTRON_DB_MANAGE_COMMAND;
    # Neutron has different database parameters
    $self->{db_version} = ["current"];
    $self->{db_sync} = [@NEUTRON_DB_BOOTSTRAP];

    $self->{filename} = \%CONF_FILE;
    $self->{daemon_map} = $self->{hypervisor} ? \%DAEMON_HYPERVISOR : \%DAEMON;
}


=pod

=back

=cut

1;
