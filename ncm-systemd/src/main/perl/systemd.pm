#${PMcomponent}

use parent qw(NCM::Component);

use Readonly;
use NCM::Component::Systemd::Service;

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

=head1 NAME

NCM::${project.artifactId} - NCM ${project.artifactId} component

=head1 Methods

=over

=item skip

The C<skip> methods determines what configuration work to skip.
It returns a hashref with key the configuration name and a boolean
value (to skip or not). Undefined configurations will be skipped.

The main purpose for this method is to allow easy subclassing for
replacement components.

=cut

sub skip
{
    my ($self, $config) = @_;
    my $skip = $config->getTree($self->prefix()."/skip");
    return $skip;
}

=item Configure()

Configures C<systemd> for each supported sub-system

=cut

sub Configure
{

    my ($self, $config) = @_;

    my $skip = $self->skip($config);

    if ((! defined($skip->{service})) || $skip->{service}) {
        $self->info("Skipping service configuration");
    } else {
        my $service = NCM::Component::Systemd::Service->new($self->prefix(), log => $self);
        $service->configure($config);
    }

    return 1;
}

=pod

=back

=cut

1; #required for Perl modules
