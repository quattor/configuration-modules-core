# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

package NCM::Component::Systemd::Service;

use 5.10.1;
use strict;
use warnings;

use parent qw(CAF::Object Exporter);

use NCM::Component::Systemd::Service::Unit;
use NCM::Component::Systemd::Service::Chkconfig;

use LC::Exception qw (SUCCESS);

use Readonly;

# these won't be turned off with default settings
# TODO add some systemd services? sysctl / rc.local
# TODO protecting network assumes ncm-network is being used
# TODO shouldn't these services be "always on"?
Readonly::Hash my %DEFAULT_PROTECTED_SERVICES => (
    network => 1,
    messagebus => 1,
    haldaemon => 1,
    sshd => 1,
);

Readonly my $BASE => "/software/components/${project.artifactId}";
Readonly my $LEGACY_BASE => "/software/components/chkconfig";

=pod

=head1 NAME

NCM::Component::Systemd::Service handles the C<ncm-systemd> services.

=head2 Public methods

=over

=item new

Returns a new object, accepts the following options

=over

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

sub _initialize
{
    my ($self, %opts) = @_;

    $self->{log} = $opts{log} if $opts{log};

    $self->{unit} = NCM::Component::Systemd::Service::Unit->new(log => $self);
    $self->{chkconfig} = NCM::Component::Systemd::Service::Chkconfig->new(log => $self);

    return SUCCESS;
}

=pod

=item configure

C<configure> gathered the to-be-configured services from the C<config> using the 
C<gather_services> method and then takes appropriate actions.

=cut

sub configure
{
    my ($self, $config) = @_;

    my $service = $self->gather_services($config);

}


=pod

=back

=head2 Private methods

=over

=item gather_services

Gather the list of all configured services from both C<ncm-systemd> 
and legacy C<ncm-chkconfig> location, and take appropriate actions.

For any service defined in both C<ncm-systemd> and C<ncm-chkconfig> location,
the C<ncm-systemd> settings will be used.

Returns a hash reference with key the service name and value the service detail.

=cut

sub gather_services
{
    my ($self, $config) = @_;

    my $services = {};

    # Gather the legacy services first (if any)
    if ($config->elementExists("$LEGACY_BASE/service")) {
        my $tree = $config->getElement("$LEGACY_BASE/service")->getTree();
        $services = $self->{chkconfig}->configured_services($tree);
    }

    # update with new-style services (if any)
    if ($config->elementExists("$BASE/service")) {
        my $tree = $config->getElement("$BASE/service")->getTree();
        my $new_services = $self->{unit}->configured_services($tree);
        while (my ($service, $detail) = each %$new_services) {
            if ($services->{$service}) {
                $self->info("Found configured service $service via $BASE and legacy $LEGACY_BASE. ",
                            "Using new style service details.");
            }
            $services->{$service} = $detail;
        }
    }

    $self->verbose("Gathered ", scalar keys %$services, " services: ", join(", ", sort keys %$services));

    return $services;
}

=pod

=back

=cut 

1;
