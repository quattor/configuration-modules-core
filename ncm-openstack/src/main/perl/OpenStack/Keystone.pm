#${PMpre} NCM::Component::OpenStack::Keystone${PMpost}

use parent qw(NCM::Component::OpenStack::Identity);

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
        # key names will replace _ with - when creating the commandline
        my %opts = (
            password => $openrc->{os_password},
            );

        my $msg = "bootstrap";

        # creates admin role and admin project
        #   no endpoints are available, those will have to be created by the client/API
        #   no region either, also with client/API
        my $cmd = [$self->{manage}, 'bootstrap'];
        foreach my $opt (sort keys %opts) {
            my $name = $opt;
            $name =~ s/_/-/g;
            push(@$cmd, "--bootstrap-$name", $opts{$opt})
        }

        # Force root and contains sensitive data
        $self->_do($cmd, $msg, user => undef, sensitive => {$openrc->{os_password} => 'PASSWORD'}) or return;
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
        $self->_do($cmd, $msg, user => undef, sensitive => 0) or return;
    }

    return $self->bootstrap_url_endpoints();
}

=pod

=back

=cut

1;
