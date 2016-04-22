#${PMpre} NCM::Component::FreeIPA::Cert${PMpost}

use Readonly;

=head1 NAME

NCM::Component::FreeIPA::Cert adds certificate related methods to
L<NCM::Component::FreeIPA::Client>.

=head2 Public methods

=over

=item cert_request

Request certificate using certificate request file C<csr> and principal C<principal>.

=cut

sub request_cert
{
    my ($self, $csr, $principal) = @_;

    return $self->do_one('cert', 'request', $csr, principal => $principal);
};

=item get_cert

Given C<serial>, retrieve the certificate and save it in file C<crt>.

=cut

sub get_cert
{
    my ($self, $serial, $crt) = @_;

    return $self->do_one('cert', 'show', $serial, out => $crt);
}

=pod

=back

=cut


1;
