#${PMcomponent}

=head1 NAME

ncm-${project.artifactId}: Configuration module for OpenStack

=head1 DESCRIPTION

ncm-openstack provides support for OpenStack configuration for:

=over

=back

=head2 Identity

=over

=item * Keystone

=back

=head2 Compute

=over

=item * Nova

=item * Nova Hypervisor

=back

=head2 Storage

=over

=item * Glance

=back

=head2 Network

=over

=item * Neutron

=item * Neutron L2

=item * Neutron L3

=item * Neutron Linuxbridge

=item * Neutron DHCP

=back

=head2 Dashboard

=over

=item * Horizon

=back

=head3 INITIAL CREATION

=over

=item The schema details are annotated in the schema file.

=item Example pan files are included in the examples folder and also in the test folders.

=back

=head1 METHODS

=cut

use parent qw(NCM::Component
              NCM::Component::OpenStack::Commands
              NCM::Component::OpenStack::Keystone
              );

use EDG::WP4::CCM::TextRender;
use CAF::FileReader;
use CAF::Service;
use Set::Scalar;
use Data::Dumper;
use Readonly;

Readonly our $KEYSTONE_CONF_FILE => "/etc/keystone/keystone.conf";
Readonly our $OPENRC_ADMIN_SCRIPT => "/root/admin-openrc.sh";
Readonly my $KEYSTONE_DB_SYNC_COMMAND => "/usr/bin/keystone-manage";
Readonly my $HOSTNAME => "/system/network/hostname";
Readonly my $DOMAINNAME => "/system/network/domainname";

our $EC=LC::Exception::Context->new->will_store_all;


=head2 process_configuration

Detect and process OpenStack configuration files.

=cut

sub process_configuration_template
{
    my ($self, $config, $type_name, $secret) = @_;
    my $type_rel;

    if ($type_name eq "horizon") {
        $type_rel = "horizon";
    } elsif ($type_name eq "openrc") {
        $type_rel = "openrc";
    } else {
        $type_rel = "openstack_common";
    };

    my $tpl = EDG::WP4::CCM::TextRender->new(
        $type_rel,
        $config,
        relpath => 'openstack',
        log => $self,
        );
    if (!$tpl) {
        $self->error("TT processing of $type_rel.tt failed: $tpl->{fail}");
        return;
    }

    return $tpl;

}

=head2 set_file_opts

Sets filewriter options.

=cut

sub set_file_opts
{
    my ($self, $service) = @_;

    my %opts = (
        mode => "0640",
        backup => ".quattor.backup",
        owner => $service,
        group => $service
    );
    $opts{log} = $self;

    return %opts;
}

=head2 detect_quattor_flag

Detects C<OpenStack> resource Quattor flag.

=cut

sub detect_quattor_flag
{
    my ($self, $resource) = @_;

    if ($resource->{QUATTOR}) {
        return 1;
    } else {
        return;
    }
}

=head2 restart_openstack_service

Restarts C<OpenStack> services after any
configuration change.

=cut

sub restart_openstack_service
{
    my ($self, $service) = @_;

    my $map = {
        keystone => ['httpd'],
        glance => ['openstack-glance-api', 'openstack-glance-registry'],
        openrc => ['httpd'],
    };

    my $srv = CAF::Service->new($map->{$service}, log => $self);

    if (defined($srv)) {
        $srv->restart();
        $self->info("$service service/s restarted.");
    };
}

=head2 populate_service_database

Populates C<Openstack> databases to be used
by the daemons.

=cut

sub populate_service_database
{
    my ($self, $service) = @_;
    my $output;

    if ($service eq 'keystone') {
        $output = $self->run_service_db_sync($KEYSTONE_DB_SYNC_COMMAND, $service);
    }

    if ($output) {
        $self->info("$service dabase was set correctly.");
    } else {
        $self->error("Unable to poputate $service database.");
        return;
    }

    return 1;
}

=head2 set_openstack_conf_file

Sets C<OpenStack> service configuration files

=cut

sub set_openstack_conf_file
{
    my ($self, $fh, $file, $service, $data) = @_;

    if (!defined($fh)) {
        if (defined($service) && defined($data)) {
            $self->error("Failed to render $service file: $file (".$data->{fail}."). Skipping");
        } else {
            $self->error("Problem rendering $file");
        }
        $fh->cancel();
        $fh->close();
    }

    if ($fh->close()) {
        return 1;
    }
    return;
}

=head2 set_openstack_service

Sets C<Openstack> configuration files and databases used by
the deamons, if the configuration file is changed the
service must be restarted afterwards.

=cut

sub set_openstack_service
{
    my ($self, $data, $service, $config_file, $fqdn, $openrc) = @_;

    my $os_templ = $self->process_configuration_template($data, $service);
    # TODO: handle undef from failure

    my %opts = $self->set_file_opts($service);
    return if ! %opts;

    $opts{sensitive} = 1 if $openrc;
    # Setup OS service conf files and populate the database(s) first
    my $fh = $os_templ->filewriter($config_file, %opts);
    my $status = $self->set_openstack_conf_file($fh, $config_file, $service, $os_templ);
    $self->populate_service_database($service) if ($service ne 'openrc');

    # Setup Fernet keys repository and Keystone identity service
    $self->bootstrap_identity_services($data, $fqdn, $openrc) if ($service eq 'keystone');

    # Restart service(s)
    $self->restart_openstack_service($service) if (defined($status));

    return $status;
}


=head2 get_fqdn

Returns C<fqdn> of the host.

=cut

sub get_fqdn
{
    my ($self,$config) = @_;

    my $hostname = $config->getElement ($HOSTNAME)->getValue;
    my $domainname = $config->getElement ($DOMAINNAME)->getValue;

    return "$hostname.$domainname";
}

=head2 Configure

Configure C<OpenStack> services resources.

=cut

sub Configure
{
    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix);
    my $fqdn = $self->get_fqdn($config);

    # Set Keystone service first
    $self->set_openstack_service($config->getElement($self->prefix."/keystone"), "keystone", $KEYSTONE_CONF_FILE, $fqdn, $tree->{openrc})
        if exists $tree->{keystone};

    # Set OpenRC script to connect to RPC Identity service
    $self->set_openstack_service($config->getElement($self->prefix."/openrc"), "openrc", $OPENRC_ADMIN_SCRIPT, $fqdn, 1);

    return 1;
}

1;
