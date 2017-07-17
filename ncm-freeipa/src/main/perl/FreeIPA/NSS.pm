#${PMpre} NCM::Component::FreeIPA::NSS${PMpost}

use parent qw(CAF::Object CAF::Path);
use CAF::Object qw(SUCCESS);
use CAF::Process;
use File::Basename qw(dirname);
use Readonly;
use Crypt::OpenSSL::X509;

# Both from nss-tools
Readonly my $CERTUTIL => '/usr/bin/certutil';
Readonly my $PK12UTIL => '/usr/bin/pk12util';
# From openssl
Readonly my $OPENSSL => '/usr/bin/openssl';

Readonly my $DEV_RANDOM => '/dev/urandom';

Readonly my $DEFAULT_CA_CERT => '/etc/ipa/ca.crt';

Readonly my $DEFAULT_CSR_BITS => 4096;

=pod

=head1 NAME

NCM::Component::FreeIPA::NSS handles the certificates using C<NSS>.

=head2 Public methods

=over

=item new

Returns a NSS object with C<nssdb>, accepts the following options

=over

=item format: dbm or sql

=item realm: IPA realm, used for CA nick

=item cacrt: IPA CA crt location, default to C</etc/ipa/ca.crt>

=item csr_bits: key size in bits for a new csr.

=item owner, group, mode: owner, group and permissions for nssdb and/or certs

=item log

A logger instance (compatible with C<CAF::Object>).

=back

=cut

# Allow to specify format? will the key retrieval still work with 'sql:'?

sub _initialize
{
    my ($self, $nssdb, %opts) = @_;

    $self->{nssdb} = $nssdb;

    $self->{format} = $opts{format} if $opts{format};
    $self->{log} = $opts{log} if $opts{log};

    $self->{perms} = {};
    foreach my $p (qw(owner group mode)) {
        $self->{perms}->{$p} = $opts{$p} if defined($opts{$p});
    }

    if ($opts{realm}) {
        $self->{realm} = $opts{realm};
        $self->{canick} = "$opts{realm} IPA CA";
    }
    $self->{cacrt} = $opts{cacrt} || $DEFAULT_CA_CERT;

    $self->{csr_bits}  = $opts{csr_bits} || $DEFAULT_CSR_BITS;

    return $nssdb ? SUCCESS : undef;
}

=item setup_nssdb

Setup and initialise nssdb dirrectory

=cut

sub setup_nssdb
{
    my ($self) = @_;

    my $msg = "nssdb directory $self->{nssdb}";

    # No directory of no .db files
    my $initdb = ! $self->directory_exists($self->{nssdb}) ||
                 ! scalar glob("$self->{nssdb}/*.db");

    if ($self->directory($self->{nssdb}, %{$self->{perms}})) {
        if ($initdb) {
            if ($self->_certutil('-N', '-f', '/dev/null')) {
                $self->verbose("initialised $msg");
            } else {
                return $self->fail("Could not initialise $msg: $self->{fail}");
            }
        }

        foreach my $dbfile (glob("$self->{nssdb}/*.db")) {
            $self->status($dbfile, %{$self->{perms}});
        }

        # TODO: selinux context
        #semanage fcontext -a -t cert_t "$NSSDB(/.*)?"
        #restorecon -FvvR $NSSDB
    } else {
        return $self->fail("Failed to create/modify $msg: $self->{fail}");
    }

    return SUCCESS;
}


=item setup

Setup temporary workdir with 0700 permissions,
and initialise nssdb using C<setup_nssdb> method.

Return SUCCESS on success, undef otherwise.

=cut

sub setup
{
    my ($self) = @_;

    $self->{workdir} = $self->directory("/tmp/quattor_nss-XXXX", mode => oct(700), temp => 1);
    if (! $self->{workdir}) {
        return $self->fail("Failed to setup temp NSS workdir: $self->{fail}");
    };

    return if ! $self->setup_nssdb();

    return SUCCESS;
}

=item add_cert_trusted

Add trusted certificate with C<nick> from file C<crt>.

=cut

sub add_cert_trusted
{
    my ($self, $nick, $crt) = @_;

    # -a ascii input/ouput
    return $self->_certutil('-A', '-n', $nick, '-t', 'CT,,', '-a', '-i', $crt);
}

=item add_cert_ca

Add trusted CA certificate (nick and file via C<canick> and C<cacrt> attributes)

=cut

sub add_cert_ca
{
    my ($self) = @_;

    return $self->add_cert_trusted($self->{canick}, $self->{cacrt});
}

=item add_cert

Add untrusted certificate to NSSDB with C<nick> from file C<cert>.

=cut

sub add_cert
{
    my ($self, $nick, $cert) = @_;

    # -a for ASCII
    return $self->_certutil('-A', '-n', $nick, '-t', 'u,u,u', '-a', '-i', $cert);
}

=item has_cert

Check if certificate for C<nick> exists in NSSDB.

If an ipa client instance is passed,
also check if the certificate is known in FreeIPA.

=cut

sub has_cert
{
    my ($self, $nick, $ipa) = @_;

    # It's quite OK that this command fails
    my $oldfail = $self->{fail};

    my $cert_txt = $self->_certutil_output('-L', '-a', '-n', $nick);
    my $res = defined($cert_txt) ? 1 : 0;

    if ($ipa && $cert_txt) {
        # TODO: handle other fp methods like md5 for fallback or sha256
        my $algo = "sha1";
        my $fpmethod = "fingerprint_$algo";
        my $decoded = Crypt::OpenSSL::X509->new_from_string($cert_txt);
        if ($decoded->can($fpmethod)) {
            my $fp = $decoded->$fpmethod();

            my $hex_serial = $decoded->serial();
            my $cert = $ipa->get_cert("0x$hex_serial");
            my $ipa_fp = $cert->{"${algo}_fingerprint"} || 'undef';

            if ($ipa_fp && uc($ipa_fp) eq uc($fp)) {
                $res = 1;
                $self->debug(1, "Found existing certificate nick $nick with serial 0x$hex_serial ",
                             "with matching FPs $fp");
            } else {
                $res = 0;
                $self->verbose("Found local certificate from nick $nick ",
                               "with $algo FP $fp that doesn't match IPA FP $ipa_fp");
            }
        } else {
            $self->warn("No cert FP method $fpmethod support. Found a cert, assume it's ok");
            $res = 1;
        }
    };

    $self->{fail} = $oldfail;
    return $res;
}

=item get_cert

Extract the certificate from NSSDB for C<nick> to file C<cert>
with owner/group/mode options..

=cut

sub get_cert
{
    my ($self, $nick, $cert, %opts) = @_;

    if (! $self->directory(dirname($cert), mode => oct(755))) {
        return $self->fail("Failed to create dirname for cert $cert: $self->{fail}");
    };

    # -a for ASCII
    if ($self->_certutil('-L', '-n', $nick, '-a', '-o', $cert) &&
        $self->status($cert, %opts)) {
        return SUCCESS;
    } else {
        $self->error("Failed to create dirname for cert $cert: $self->{fail}");
        return;
    };
};

# Wrapper to read random C<bytes> from /dev/urandom
# and create a temp file from it
# Is a method so it can be unittested (does not use CAF::File, but sysread/syswrite in binmode)
# Returns (temp) filename with random data.
sub _mk_random_data
{
    my ($self, $bytes, $suff) = @_;

    $bytes = $DEFAULT_CSR_BITS if ! defined($bytes);

    $suff = 'no_dn' if ! defined($suff);

    my $sysrw = sub {
        my ($mode, $file, $data) = @_;

        my $is_read = $mode eq 'read';

        if ($CAF::Object::NoAction) {
            return -1;
        }

        my ($fh, $err);
        if (open($fh, $is_read ? '<' : '>', $file)) {
            binmode($fh);
            # No references with CORE functions to make a nicer dispatch table
            # Cannot store same args in @args
            my $bytes_read = $is_read ? sysread($fh, $data, $bytes) : syswrite($fh, $data, $bytes);
            if ($bytes_read != $bytes) {
                $err = "Only $mode $bytes_read from $file ($bytes requested)";
            };
            close($fh);
        } else {
            $err = "Failed to open/$mode $file: $!";
        };

        if ($err) {
            return $self->fail($err);
        } else {
            return $data;
        };
    };

    my $randomdata = &$sysrw('read', $DEV_RANDOM);
    if ($randomdata) {
        my $filename = "$self->{workdir}/random_$suff.data";
        if (&$sysrw('write', $filename, $randomdata)) {
            return $filename;
        }
    }
    return;
}

=item make_cert_request

Make a certificate request for C<fqdn> and optional C<dn>,
return filename of the CSR.
(Used DN is C<<CN=<fqdn>,O=<realm>>>).

=cut

sub make_cert_request
{
    my ($self, $fqdn, $dn) = @_;

    my $suff;
    if (defined($dn)) {
        $suff = "$dn";
    } else {
        $suff = "__no_dn";
    };

    my $random_data_file = $self->_mk_random_data($DEFAULT_CSR_BITS, $suff);
    return if ! $random_data_file;

    my $csr_filename = "$self->{workdir}/cert_${fqdn}_$suff.csr";

    # cleanup of random.data done by cleanup of workdir
    return $csr_filename if $self->_certutil(
        '-R', '-g', $self->{csr_bits},
        '-s', "CN=$fqdn,O=$self->{realm}",
        '-z', $random_data_file,
        '-a', '-o', $csr_filename,
        );
}


=item ipa_request_cert

Use C<NCM::Component::FreeIPA::Client> instance C<ipa> to make the certificate request
using C<csr> file. The certificate is stored in C<crt> file.

(The C<ipa> instance should be usable, e.g. the correct kerberos
environment is already setup).

Return 1 on success, undef otherwise.

=cut

sub ipa_request_cert
{
    my ($self, $csr, $crt, $fqdn, $ipa) = @_;

    my $res;

    my $principal = "host/$fqdn\@$self->{realm}";
    my $req = $ipa->request_cert($csr, $principal);
    if ($req) {
        my $serial = $req->{serial_number};

        if ($serial) {
            my $cert = $ipa->get_cert($serial, $crt);
            if ($cert) {
                $self->verbose("Retrieved certificate $cert->{certificate} with serial $cert->{serial_number} to $crt");
                $res = SUCCESS;
            } else {
                $self->fail("Failed to get certificate with serial $serial to $crt");
            }
        } else {
            $self->fail("Failed to get serial from request (csr $csr and principal $principal)");
        }
    } else {
        $self->fail("Failed to request certificate using csr $csr and principal $principal");
    }

    return $res;
}

=item get_privkey

Retrieve the private key from certificate with nick C<nick> and
save it in the file C<key> with owner/group/mode options.

=cut

sub get_privkey
{
    my ($self, $nick, $key, %opts) = @_;

    if (! $self->directory(dirname($key), mode => oct(755))) {
        return $self->fail("Failed to create dirname for key $key: $self->{fail}");
    };

    my $p12dir = "$self->{workdir}/p12keys";
    return if ! $self->directory($p12dir, mode => oct(700));

    my $p12key = "$p12dir/key.p12";
    my $out = CAF::Process->new(
        [$PK12UTIL, '-o', $p12key, '-n', $nick, '-d', $self->{nssdb}, '-W', ''],
        log => $self,
        )->output();
    if ($?) {
        $self->cleanup($p12dir);
        chomp($out);
        return $self->fail("Failed to extract p12key $p12key: $out");
    } else {
        $out = CAF::Process->new(
            [$OPENSSL, 'pkcs12', '-in', $p12key, '-out', $key, '-nodes', '-password', 'pass:'],
            log => $self,
            )->output();
        my $ec = $?;

        $self->cleanup($p12dir);

        if ($ec) {
            chomp($out);
            return $self->fail("Failed to create key $key from p12key $p12key: $out");
        } else {
            return if ! $self->status($key, %opts);
        }
    }
    return SUCCESS;
}

=item get_cert_or_key

Given C<type>, retrieve the cert of private key
from certificate with nick C<nick> and
save it in the file C<fn> with owner/group/mode options.

=cut

sub get_cert_or_key
{
    my $self = shift;
    my $type = shift;
    return $type eq 'cert' ? $self->get_cert(@_) : $self->get_privkey(@_);
}

# Convenience wrapper around certutil
# Return output (always defined) on success
# Store commandline and output on failure in fail attribute
sub _certutil_output
{
    my ($self, @args) = @_;

    my $db = $self->{nssdb};
    $db = "$self->{format}:$db" if $self->{format};

    my $proc = CAF::Process->new([$CERTUTIL, '-d', $db], log => $self);
    $proc->pushargs(@args);
    my $output = $proc->output();
    $output = '' if ! defined($output);

    chomp($output);

    if ($?) {
        return $self->fail("$proc failed: $output");
    } else {
        return $output;
    }
}

# Convenience wrapper around certutil tool via _certutil_output
# Return 1 on success
# Store commandline and output on failure in fail attribute
sub _certutil
{
    my $self = shift;
    my $output = $self->_certutil_output(@_);

    return defined($output) ? SUCCESS : undef;
}


sub DESTROY
{
    my ($self) = shift;

    # Altough workdir is a tempdir with CLEANUP
    # no harm in doing the decent thing
    if (! $self->cleanup($self->{workdir})) {
        $self->warn("Cleaning up workdir $self->{workdir} failed: $self->{fail}");
    }
}

=pod

=back

=cut


1;
