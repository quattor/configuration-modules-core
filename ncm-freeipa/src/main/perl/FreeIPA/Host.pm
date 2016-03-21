#${PMpre} NCM::Component::FreeIPA::Host${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::Host adds host related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item add_host

Add a host. If the host already exists, will try to modify any optional attributes.
(It will not delete attributes).

=over

=item Arguments

=over

=item fqdn: FQDN hostname

=back

=item Options

=over

=item ip: IP to configure DNS entry

=item network: network to use when configuring DNS entry

=item netmask: netmask to use when configuring DNS entry

=item mac: macaddress

=back

=back

=cut

sub add_host
{
    my ($self, $fqdn, %opts) = @_;

    my $host = $self->find_one("host", $fqdn);
    if ($host) {
    }
}

=item disable_host

Disable a host with C<fqdn> hostname.

=cut

sub disable_host
{
    my ($self, $fqdn) = @_;
}

=item host_passwd

Reset and return the one-time password for host C<fqdn>.
Returns undef if the host already has a keytab or if it doesn't exist.

=cut

sub host_passwd
{
    my ($self, $fqdn) = @_;

    if ($self->api_host_mod($fqdn, random => 1)) {
        return $self->{result}->{randompassword};
    } else {
        $self->error("host_passwd failed");
        return;
    };
}

=pod

=back

=cut


1;
