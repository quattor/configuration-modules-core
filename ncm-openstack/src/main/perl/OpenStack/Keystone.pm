#${PMpre} NCM::Component::OpenStack::Keystone${PMpost}

use parent qw(NCM::Component::OpenStack::Service);

use Readonly;


=head2 Methods

=over

=item _attrs

Override C<daemons> attribute

=cut

sub _attrs
{
    my $self = shift;

    $self->{daemons} = ['httpd'];
}

=item bootstrap_url_endpoints

Bootstraps URL identity service endpoints in C<Keystone>.

=cut

sub bootstrap_url_endpoints
{
    my ($self) = @_;

    my $openrc = $self->{comptree}->{openrc};
    if ($openrc) {
        # TODO: switch/support to https
        my $proto = "http";
        # TODO: support other versions of the endpoint
        my $version = 'v3';

        # key names will replace _ with - when creating the commandline
        my %opts = (
            password => $openrc->{os_password},
            region_id => $openrc->{os_region_name},
            internal_url => "$proto://$self->{fqdn}:35357/$version/",
            public_url => "$proto://$self->{fqdn}:5000/$version/",
            # TODO: no separate admin-url?
            admin_url => "$proto://$self->{fqdn}:35357/$version/",
            );

        my $msg = "bootstrap for internal: $opts{internal_url} and public: $opts{public_url} URLs";

        my $cmd = [$self->{manage}, 'bootstrap'];
        foreach my $opt (sort keys %opts) {
            my $name = $opt;
            $name =~ s/_/-/g;
            push(@$cmd, "--bootstrap-$name", $opts{$opt})
        }

        # Force root and contains sensitive data
        $self->_do($cmd, $msg, user => undef, sensitive => 1) or return;
    } else {
        $self->error("bootstrap_url_endpoint has no openrc config");
        return;
    }
    return 1;
}

=item post_populate_service_database

Initializes Fernet key repositories and
bootstrap C<Keystone> identity services.

=cut

sub post_populate_service_database
{
    my ($self) = @_;

    foreach my $method (qw(fernet credential)) {
        # Keystone manage commands
        # More info: https://docs.openstack.org/keystone/latest/cli/index.html#keystone-manage
        my $cmd = [$self->{manage}, "${method}_setup", qw(--keystone-user keystone --keystone-group keystone)];
        my $msg = "Fernet key repository set correctly for $method encryption.";
        # Force root and contains sensitive data
        $self->_do($cmd, $msg, user => undef, sensitive => 1) or return;
    }

    return $self->bootstrap_url_endpoints();
}

=pod

=back

=cut

1;
