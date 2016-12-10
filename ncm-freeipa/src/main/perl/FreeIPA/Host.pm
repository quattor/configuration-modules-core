#${PMpre} NCM::Component::FreeIPA::Host${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::Host adds host related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item add_host

Add a host. If the host already exists, return undef.

=over

=item Arguments

=over

=item fqdn: FQDN hostname

=back

=item Options (passed to C<Net::FreeIPA::API::api_host_add>).

=over

=item ip_address: IP to configure DNS entry

=item macaddress: macaddress

=back

=back

=cut

sub add_host
{
    my ($self, $fqdn, %opts) = @_;

    return $self->do_one('host', 'add', $fqdn, %opts);
}

=item disable_host

Disable a host with C<fqdn> hostname.

=cut

sub disable_host
{
    my ($self, $fqdn) = @_;

    return $self->do_one('host', 'disable', $fqdn);
}

=item remove_host

Remove the host C<fqdn>.

=cut

sub remove_host
{
    my ($self, $fqdn) = @_;

    return $self->do_one('host', 'del', [$fqdn], updatedns => 1);
}

=item host_passwd

Reset and return the one-time password for host C<fqdn>.
Returns undef if the host already has a keytab or if it doesn't exist.

=cut

sub host_passwd
{
    my ($self, $fqdn) = @_;

    return $self->do_one('host', 'mod', $fqdn, random => 1, __result_path => 'result/result/randompassword');
}

=pod

=back

=cut


1;
