#${PMpre} NCM::Component::OpenStack::Neutron${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;

Readonly our $NEUTRON_CONF_FILE => "/etc/neutron/neutron.conf ";
Readonly our $ML2_CONF_FILE => "/etc/neutron/plugins/ml2/ml2_conf.ini";
Readonly our $LINUXBRIDGE_CONF_FILE => "/etc/neutron/plugins/ml2/linuxbridge_agent.ini";
Readonly our $L3_AGENT_CONF_FILE => "/etc/neutron/l3_agent.ini";
Readonly our $DHCP_AGENT_CONF_FILE => "/etc/neutron/dhcp_agent.ini";
Readonly our $METADATA_AGENT_CONF_FILE => "/etc/neutron/metadata_agent.ini";
Readonly our $NEUTRON_DB_MANAGE_COMMAND => "/usr/bin/neutron-db-manage";
Readonly our $NEUTRON_DB_BOOTSTRAP => "--config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head";

=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{manage} = $NEUTRON_DB_MANAGE_COMMAND;
    $self->{daemons} = [
        'neutron-server',
        'neutron-linuxbridge-agent',
        'neutron-dhcp-agent',
        'neutron-metadata-agent',
        'neutron-l3-agent',
    ];
    # Neutron has different database parameters
    $self->{db_version} = "current";
    $self->{db_sync} = $NEUTRON_DB_BOOTSTRAP;
}

=item post_populate_service_database

Neutron post db_sync execution

=cut

sub post_populate_service_database
{
    my ($self) = @_;
    return 1;
}


=pod

=back

=cut

1;
