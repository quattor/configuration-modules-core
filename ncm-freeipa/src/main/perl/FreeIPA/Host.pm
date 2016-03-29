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

=item Options

=over

=item ip_address: IP to configure DNS entry

=item macaddress: macaddress

=back

=back

=cut

sub add_host
{
    my ($self, $fqdn, %opts) = @_;

    if ($self->find_one("host", $fqdn)) {
        $self->debug("add_host: host $fqdn already exists");
        return;
    } else {
        if ($self->api_host_add($fqdn, %opts)) {
            return $self->{result};
        } else {
            $self->error("add_host failed for host $fqdn");
            return;
        };
    };
}

=item disable_host

Disable a host with C<fqdn> hostname.

=cut

sub disable_host
{
    my ($self, $fqdn) = @_;

    if ($self->find_one("host", $fqdn)) {
        if ($self->api_host_disable($fqdn)) {
            return $self->{result};
        } else {
            $self->error("disable_host failed for host $fqdn");
            return;
        };
    } else {
        $self->debug("disable_host: host $fqdn does not exist.");
        return;
    }
}

=item remove_host

Remove the host C<fqdn>.

=cut

sub remove_host
{
    my ($self, $fqdn) = @_;

    if($self->find_one("host", $fqdn)) {
        if ($self->api_host_del($fqdn, updatedns => 1)) {
            return $self->{result};
        } else {
            $self->error("remove_host failed for host $fqdn");
            return;
        };
    } else {
        $self->debug("remove_host: no host $fqdn");
    }
}

=item host_passwd

Reset and return the one-time password for host C<fqdn>.
Returns undef if the host already has a keytab or if it doesn't exist.

=cut

sub host_passwd
{
    my ($self, $fqdn) = @_;

    if($self->find_one("host", $fqdn)) {
        if ($self->api_host_mod($fqdn, random => 1)) {
            return $self->{result}->{randompassword};
        } else {
            $self->error("host_passwd failed for host $fqdn");
            return;
        };
    } else {
        $self->debug("host_passwd: no host $fqdn");
    }
}

=pod

=back

=cut


1;
