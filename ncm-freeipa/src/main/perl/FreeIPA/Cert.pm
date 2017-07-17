#${PMpre} NCM::Component::FreeIPA::Cert${PMpost}

use CAF::FileReader;

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

    # Strip leading/trailing garbage
    my $reg = qr{^(-----BEGIN (?:NEW )?CERTIFICATE REQUEST-----.*-----END (?:NEW )?CERTIFICATE REQUEST-----)$}ms;

    # Extract the cert request
    # No CAF::Reporter instance around?
    my %opts;
    if ($self->{log} && $self->{log}->{reporter}) {
        $opts{log} = $self->{log}->{reporter};
    }

    my $fh = CAF::FileReader->new($csr, %opts);
    if ($fh) {
        # Strip leading/trailing garbage
        if ("$fh" =~ m/$reg/) {
            return $self->do_one('cert', 'request', $1, principal => $principal);
        } else {
            $self->error("Read CSR file $csr with unexpected content (pattern to match $reg): $fh");
        }
    } else {
        $self->error("Failed to read CSR file $csr");
    }
    return;
};

=item get_cert

Given C<serial>, retrieve the certificate and when defined,
save it in file C<crt>.

=cut

sub get_cert
{
    my ($self, $serial, $crt) = @_;

    my $cert = $self->do_one('cert', 'show', $serial);

    if ($crt && $cert) {
        # Extract the cert request
        # No CAF::Reporter instance around?
        my %opts;
        if ($self->{log} && $self->{log}->{reporter}) {
            $opts{log} = $self->{log}->{reporter};
        }
        my $fh = CAF::FileWriter->new($crt, %opts);
        print $fh "$cert->{certificate}\n";
        $fh->close();
    }

    return $cert;
}

=pod

=back

=cut


1;
