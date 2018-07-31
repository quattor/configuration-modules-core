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

=head2 Messaging

=over

=item * RabbitMQ

=back

=head3 INITIAL CREATION

=over

=item The schema details are annotated in the schema file.

=item Example pan files are included in the examples folder and also in the test folders.

=back

=head1 METHODS

=cut

use parent qw(NCM::Component);

use NCM::Component::OpenStack::Service qw(run_service);
use NCM::Component::OpenStack::Client qw(set_logger);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;


=head2 Configure

Configure C<OpenStack> services resources.

=cut

sub Configure
{
    my ($self, $config) = @_;

    # Set client logger. Doesn't mean the client has to be used.
    set_logger($self);

    my $tree = $config->getTree($self->prefix);

    my @args = ($config, $self, $self->prefix);

    my $order = [
        # First set OpenRC script to connect to REST API
        # This is not a regular OpenStack service
        'openrc',
        # And messaging service if available
        'messaging',
        # Set OpenStack identity service first
        'identity',
        # After that continue with the rest of services
        'storage',
        'volume',
        'share',
        'compute',
        'network',
        'orchestration',
        'dashboard',
    ];

   foreach my $type (@$order) {
       if (exists($tree->{$type})) {
           run_service($type, @args) or return;
       }
    }

    return 1;
}

1;
