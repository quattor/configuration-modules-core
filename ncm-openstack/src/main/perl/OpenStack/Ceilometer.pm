#${PMpre} NCM::Component::OpenStack::Ceilometer${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;
use Data::Dumper;

Readonly our $GNOCCHI_DB_MANAGE_COMMAND => "/usr/bin/gnocchi-upgrade";
Readonly our $CEILOMETER_DB_MANAGE_COMMAND => "/usr/bin/ceilometer-upgrade";

Readonly::Array my @CEILOMETER_DB_BOOTSTRAP => qw(--debug);
Readonly::Array my @CEILOMETER_DB_VERSION => qw(--version);

Readonly::Hash my %CONF_FILE => {
    service => "/etc/ceilometer/ceilometer.conf",
    gnocchi => "/etc/gnocchi/gnocchi.conf",
};

Readonly::Hash my %DAEMON => {
    service => ['openstack-ceilometer-notification', 'openstack-ceilometer-central'],
    gnocchi => ['openstack-gnocchi-metricd', 'httpd'],
};

Readonly::Hash my %DAEMON_HYPERVISOR => {
    service => ['openstack-ceilometer-compute', 'openstack-ceilometer-ipmi'],
};


=head2 Methods

=over

=item _attrs

Override C<manage>, C<db> and C<filename> attribute (and set C<daemon_map>)

=cut

sub _attrs
{
    my $self = shift;

    $self->{manage} = $self->{hypervisor} ? undef : $CEILOMETER_DB_MANAGE_COMMAND;
    #delete $self->{manage};
    # Ceilometer has no database parameters
    $self->{db_version} = [@CEILOMETER_DB_VERSION];
    $self->{db_sync} = [@CEILOMETER_DB_BOOTSTRAP];
    $self->{filename} = \%CONF_FILE;
    $self->{fileownergroup}->{$CONF_FILE{gnocchi}} = {
        user => 'gnocchi',
        group => 'gnocchi',
    };
    $self->{daemon_map} = $self->{hypervisor} ? \%DAEMON_HYPERVISOR : \%DAEMON;
}

=item pre_populate_service_database

Initializes C<Gnocchi> database for C<Ceilometer> metric service.
This should be done before C<Ceilometer> database bootstrap.

=cut

sub pre_populate_service_database
{
    my ($self) = @_;

    my $cmd = [$GNOCCHI_DB_MANAGE_COMMAND];
    $self->_do($cmd, "pre-populate Gnocchi database", sensitive => 0, user => 'gnocchi')
        or return;

    return 1;
}

=pod

=back

=cut

1;
