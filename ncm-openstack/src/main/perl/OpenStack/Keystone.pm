#${PMpre} NCM::Component::OpenStack::Keystone${PMpost}

use Sys::Hostname;
use Readonly;


=head1 NAME

C<NCM::Component::OpenStack::Keystone> adds C<OpenStack> C<Identity> 
service configuration support to L<NCM::Component::OpenStack>.

=head2 Public methods

=over


=item bootstrap_url_endpoints

Bootstraps URL identity service endpoints in C<Keystone>.

=cut

sub bootstrap_url_endpoints
{
    my ($self, $data, $fqdn, $openrc) = @_;

    my $password = $openrc->{os_password};
    my $region = $openrc->{os_region_name};
    my $internal_url = "http://$fqdn:35357/v3/";
    my $public_url = "http://$fqdn:5000/v3/";

    my $cmd = [join(' ', '--bootstrap-password', $password), join(' ', "--bootstrap-admin-url", $internal_url),
        join(' ', "--bootstrap-internal-url", $internal_url), join(' ', "--bootstrap-public-url", $public_url),
        join(' ', "--bootstrap-region-id", $region)];

    my $output = $self->run_url_bootstrap($cmd);
    if ($output) {
        $self->info("Executed bootstrap for internal: $internal_url and public: $public_url URLs");
    } else {
        $self->error("Unable to bootstrap internal: $internal_url and public: $public_url URLs");
        return;
    }
    return 1;
}

=item bootstrap_identity_services

Initializes Fernet key repositories and
bootstrap C<Keystone> identity services.

=cut

sub bootstrap_identity_services
{
    my ($self, $data, $fqdn, $openrc) = @_;
    my @methods = qw(fernet credential);


    foreach my $method (@methods) {
        my $run_fernet_method = "run_${method}_setup";
        my $output = $self->$run_fernet_method();

        if ($output) {
            $self->info("Fernet key repository set correctly for $method encryption.");
        } else {
            $self->error("Unable to set Fernet key repository for $method encryption.");
            return;
        }
    }

    return $self->bootstrap_url_endpoints($data, $fqdn, $openrc);
}

=pod

=back

=cut

1;
