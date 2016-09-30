#${PMpre} NCM::Component::download${PMpost}

use parent qw(NCM::Component CAF::Path);

our $EC = LC::Exception::Context->new->will_store_all;

use File::Temp qw(tempdir);
use CAF::Process;
use POSIX;
use Readonly;

# Lexical scope for Readonly set in BEGIN{}
my ($HTTPS_CLASS_NET_SSL, $HTTPS_CLASS_IO_SOCKET_SSL, $LWP_MINIMAL, $LWP_CURRENT);
# Keep track of default class from BEGIN
my $_default_https_class;

# Although reset by ComponentProxy, let's be polite
local %ENV;

BEGIN {
    Readonly $HTTPS_CLASS_NET_SSL => 'Net::SSL';
    Readonly $HTTPS_CLASS_IO_SOCKET_SSL => 'IO::Socket::SSL';

    # From the el6 perl-libwww-perl changelog:
    #   Implement hostname verification that is disabled by default. You can install
    #   IO::Socket::SSL Perl module and set PERL_LWP_SSL_VERIFY_HOSTNAME=1
    #   enviroment variable (or modify your application to set ssl_opts option
    #   correctly) to enable the verification.
    # So this version supports ssl_opts and supports verify_hostname for IO::Socket::SSL
    Readonly $LWP_MINIMAL => version->new('5.833');

    # This does not load Net::HTTPS by itself
    use LWP::UserAgent;
    $_default_https_class = $HTTPS_CLASS_NET_SSL;
    my $vtxt = $LWP::UserAgent::VERSION;
    if ($vtxt =~ m/(\d+\.\d+)/) {

        Readonly $LWP_CURRENT => version->new($1);

        if ($LWP_CURRENT >= $LWP_MINIMAL) {
            # Use system defaults
            $_default_https_class = undef;
        }
    }

    # This doesn't do anything on EL5?
    $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = $_default_https_class;
}

# Keep this outside the BEGIN{} block
use Net::HTTPS;

use LWP::Authen::Negotiate;

use EDG::WP4::CCM::Element qw(unescape);
use CAF::Object qw(SUCCESS);

$NCM::Component::download::NoActionSupported = 1;

# Hold the credential cache location / KRB5CCNAME value
my $_gss_tmpdir;
my $_cached_gss;

# TODO: Move this together with the BEGIN{} elsewhere, e.g. CAF::Download or CCM::Fetch::Download

=pod

=head1 FUNCTIONS

=over

=item _lwp_ua

Initialise LWP::UserAgent and run C<method> with arrayref C<args>.
Best-effort to handle ssl setup, Net::SSL vs IO::Socket::SSL
and verify_hostname.

Returns the result of the method or undef.

Options

=over

=item cacert: the CA file

=item cadir: the CA path

=item cert: the client certificate filename

=item key: the client certificate private key filename

=item gss_ccache: the C<KRB5CCNAME> environment variable

=item timeout: set timeout (if defined)

=back

=cut


sub _lwp_ua
{
    my ($self, $method, $args, %opts) = @_;

    # This is a mess.

    # Set this again; very old Net::HTTPS (like in EL5) does not set the class
    # on the initial import in the BEGIN{} section
    $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = $_default_https_class;

    my $https_class = $Net::HTTPS::SSL_SOCKET_CLASS;
    if ($_default_https_class && $https_class ne $_default_https_class) {
        # E.g. when LWP was already used by previous component
        # No idea how to properly change/force it to the class we expect
        $self->verbose("Unexpected Net::HTTPS SSL_SOCKET_CLASS: found $https_class, expected $_default_https_class");
    } else {
        $self->debug(3, "Using Net::HTTPS SSL_SOCKET_CLASS $https_class");
    }

    my %lwp_opts;

    # Disable by default, for legacy reasons and because
    # Net::SSL does not support it (even in el7)
    my $verify_hostname = 0;

    if (!defined($LWP_CURRENT)) {
        $self->verbose("Invalid LWP::UserAgent version $LWP::UserAgent::VERSION found. Assuming very ancient system");
    } elsif ($LWP_CURRENT >= $LWP_MINIMAL) {
        $self->debug(3, "Using LWP::UserAgent version $LWP_CURRENT");
        if ($https_class eq $HTTPS_CLASS_IO_SOCKET_SSL) {
            $self->debug(2, "LWP::UserAgent is recent enough to support verify_hostname for $HTTPS_CLASS_IO_SOCKET_SSL");
            $verify_hostname = 1;
        };

        my $ssl_opts = {
            verify_hostname => $verify_hostname,
        };

        $ssl_opts->{SSL_ca_file} = $opts{cacert} if $opts{cacert};
        $ssl_opts->{SSL_ca_path} = $opts{cadir} if $opts{cadir};
        $ssl_opts->{SSL_cert_file} = $opts{cert} if $opts{cert};
        $ssl_opts->{SSL_key_file} = $opts{key} if $opts{key};

        $self->debug(3, "Using LWP::UserAgent ssl_opts ", join(" ", map {"$_: ".$ssl_opts->{$_}} sort keys %$ssl_opts));
        $lwp_opts{ssl_opts} = $ssl_opts;
    }

    # ssl_opts override any environment vars; but just in case
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = $verify_hostname;

    if ($https_class eq $HTTPS_CLASS_NET_SSL) {
        # Probably not needed anymore in recent version,
        # they are set via ssl_opts
        # But this just in case (e.g. EL5)
        $ENV{HTTPS_CERT_FILE} = $opts{cert} if $opts{cert};
        $ENV{HTTPS_KEY_FILE} = $opts{key} if $opts{key};

        # What do these do in EL5?
        $ENV{HTTPS_CA_FILE} = $opts{cacert} if $opts{cacert};
        $ENV{HTTPS_CA_DIR} = $opts{capath} if $opts{capath};
    } elsif ($https_class eq $HTTPS_CLASS_IO_SOCKET_SSL) {
        # nothing needed?
        # one could try to set the IO::Socket::SSL::set_ctx_defaults
        # see http://stackoverflow.com/questions/74358/how-can-i-get-lwp-to-validate-ssl-server-certificates#5329129
        # but el6 changelog says this is not necessary
    } else {
        # This is not supported
        $self->error("Unsupported Net::HTTPS SSL_SOCKET_CLASS $https_class");
        return;
    }

    # Required for LWP::Authen::Negotiate
    $ENV{KRB5CCNAME} = $opts{gss_ccache} if $opts{gss_ccache};

    my $lwp = LWP::UserAgent->new(%lwp_opts);
    $lwp->timeout($opts{timeout}) if (defined($opts{timeout}));

    my $res = $lwp->$method(@$args);

    return $res;
}


sub get_gss_token
{
    my $self = shift;

    # Return module wide cache value
    return $_cached_gss if $_cached_gss;

    $_gss_tmpdir = tempdir("ncm-download-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    $self->debug(1, "storing kerberos credentials in $_gss_tmpdir");

    my $ccache = "FILE:$_gss_tmpdir/host.tkt";
    $ENV{KRB5CCNAME} = $ccache;

    # Just in case...
    my $krb_bin = "/usr/kerberos/bin";
    $ENV{PATH} = "$ENV{PATH}:$krb_bin" if -d $krb_bin;

    # Assume "kinit" is in the PATH.
    my $errs = "";
    my $proc = CAF::Process->new(["kinit", "-k"],
                                 stderr => \$errs,
                                 log => $self,
                                 keeps_state => 1);
    $proc->execute();
    if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
        $self->error("could not get GSSAPI credentials: $errs");
        return;
    }

    # Only set it now
    $_cached_gss = $ccache;
    return $_cached_gss;
}

sub Configure
{
    my ($self, $config)=@_;

    my $tree = $config->getTree($self->prefix);

    my $defserver = $tree->{server} || "";
    my $defproto = $tree->{proto} || "";

    my $proxyhosts = $tree->{proxyhosts} || [];

    foreach my $esc_fn (sort keys %{$tree->{files}}) {
        my $fn = unescape($esc_fn);
        my $file = $tree->{files}->{$esc_fn};

        # Sanitize file details
        $file->{server} = $defserver if ! exists($file->{server});
        $file->{proto} = $defproto if ! exists($file->{proto});

        $file->{min_age} = 0 if ! $file->{min_age};

        # TODO: tree->{timeout} can be undef; default via schema?
        $file->{timeout} = $tree->{timeout} if ! exists($file->{timeout});
        # TODO: there's no per-file setting yet?
        $file->{head_timeout} = $tree->{head_timeout};

        if ($file->{gssapi}) {
            $file->{gss_ccache} = $self->get_gss_token();
            # immediate failure
            return 0 if ! $file->{gss_ccache};
        }


        # download
        next if ! $self->download($fn, $file, $proxyhosts);

        # post-processing
        my $cmd = $file->{post};
        if ($cmd) {
            my $errs = "";
            my $proc = CAF::Process->new([$cmd, $fn],
                                         stderr => \$errs,
                                         log => $self);
            $proc->execute();
            if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                $self->error("post-process $cmd of $fn gave errors: $errs");
            }
        }

        $self->info("successfully processed file $fn");
    }

    return 1;
}


# download: highlevel method, actual transfer code is in retrieve method
# fn is the destination filename to download to
# file is a hashref with download details
# proxyhosts is a array with proxy hosts (the arrayref might be modified)
sub download
{
    my ($self, $fn, $file, $proxyhosts) = @_;

    # Sanitize source
    my $source = $file->{href};
    if ($source !~ m{^[a-z]+://.*}) {
        # an incomplete URL... let's add defaults
        if ($source !~ m{^/}) {
            $source = "/$source";
        }

        if ($source !~ m{^//}) {
            if ($file->{server}) {
                $source = "//$file->{server}$source";
            } else {
                # TODO: ignoring with an error?
                #       better would be to force this being non-empty via schema
                #       (eg no empty server attribute; or no empty server without default server specified),
                #       and not support ignoring files with error reported
                $self->error("$fn requested but no server, ignoring");
                return;
            }
        }

        if ($source =~ m{^//}) {
            # server specified, but no proto
            if ($file->{proto}) {
                $source = "$file->{proto}:$source";
            } else {
                # TODO: ignoring with error?
                $self->error("$fn requested but no proto, ignoring");
                return;
            }
        }
    }

    my %opts = (
        href => $source,
        gss_ccache => $file->{gss_ccache},
        cacert => $file->{cacert},
        capath => $file->{capath},
        cert => $file->{cert},
        key =>  $file->{key},
        min_age => $file->{min_age},
        # TODO: head_timeout used to be only per file for proxies, and per component for non-proxy
        head_timeout => $file->{head_timeout},
        # TODO: timeout used to be only per file for proxies, and not at all for non-proxy
        timeout => $file->{timeout},
        );

    my $success = 0;
    if (@$proxyhosts && $file->{proxy}) {
        my $attempts = scalar @$proxyhosts;
        while ($attempts--) {
            # take the head off the list and rotate to the end...
            # we do this in order to avoid continually trying a dead
            # proxy - once we've found one that works, we'll keep using it.
            my $proxy = shift @$proxyhosts;
            $self->debug(3, "Trying proxy $proxy for source $source and filename $fn");
            $success += $self->retrieve(
                $fn,
                proxy => $proxy,
                %opts);

            if ($success) {
                # add succesful proxy at begin
                unshift @$proxyhosts, $proxy;
                last;
            } else {
                # add failed proxy at the back
                push @$proxyhosts, $proxy;
            }
        }

        if (!$success) {
            $self->warn("failed to retrieve $source to $fn from any proxies (",
                        join(',', @$proxyhosts), "), using original");
        }
    }

    if (!$success) {
        if (!$self->retrieve($fn, %opts)) {
            $self->error("failed to retrieve $source to $fn, skipping");
            return;
        }
    }

    my %perms = map {$_ => $file->{$_}} grep {defined $file->{$_}} qw(owner group);
    $perms{mode} = $file->{perm} if defined($file->{perm});

    if (%perms) {
        my $msg = "$fn to ".join(" ", map{"$_=".$perms{$_}} sort keys %perms);
        # TODO use CAF::Path, this is not noaction safe
        my $r = LC::Check::status($fn, %perms);
        # $r == 0 means there was no change
        if ($r > 0) {
            $self->info("updated $msg");
        } elsif ($r < 0) {
            # TODO: returning failure here. this did not used to be the case
            $self->error("failed to update perms/ownership of $msg");
            return;
        }
    }

    $self->verbose("Succesful download of file $fn");

    return SUCCESS;
}


sub get_remote_timestamp
{
    my ($self, $source, %opts) = @_;

    $opts{timeout} = $opts{head_timeout} if defined($opts{head_timeout});

    my $head = $self->_lwp_ua('head', [$source], %opts);
    if ($head && $head->is_success()) {
        my $mtime = $head->headers->last_modified();
        $self->debug(3, "head for $source was success, returning last_modified $mtime");
        return $mtime;
    } else {
        # Status line starts with code
        $self->debug(1, "head for $source failed with ", $head->status_line());
        return;
    }
}

# Single attempt, actual transfer
sub retrieve
{
    my ($self, $fn, %opts) = @_;

    my $source  = $opts{href};
    my $timeout = $opts{timeout};
    my $proxy   = $opts{proxy} || "";

    my $gss_ccache  = $opts{gss_ccache};

    my $min_age = $opts{min_age} || 0;

    $self->debug(1, "Retrieving file $fn from $source");

    my @cmd = (qw(/usr/bin/curl -s -R -f --create-dirs -o), $fn);

    if ($proxy) {
        $source =~ s{^([a-z]+)://([^/]+)/}{$1://$proxy/};
    }

    if ($timeout) {
        push @cmd, ("-m", $timeout);
    }

    if ($gss_ccache) {
        # If negotiate extension is required, then we'll
        # enable it and put in a dummy username/password.
        $ENV{KRB5CCNAME} = $gss_ccache;
        push @cmd, qw(--negotiate -u x:x);
    }

    foreach my $key (qw(key cacert capath cert)) {
        push(@cmd, "--$key", $opts{$key}) if $opts{$key};
    }

    push @cmd, $source;

    # Get timestamp of any existing file, defaulting to zero if the
    # file doesn't exist
    my $timestamp_existing = 0;
    if (-e $fn) {
        $timestamp_existing  = (stat($fn))[9];
    }

    # Turn minutes into seconds and calculate the threshold that the remote timestamp must be below
    my $timestamp_threshold = (time() - ($min_age * 60));
    my $timestamp_remote = $self->get_remote_timestamp($source, %opts);
    if ($timestamp_remote) {
        if ($timestamp_remote > $timestamp_existing) { # If local file doesn't exist, this still works
            if ($timestamp_remote <= $timestamp_threshold) { # Also prevents future files
                my $proc = CAF::Process->new(\@cmd, stderr => \my $errs, log => $self);
                $proc->execute();
                if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                    # Only warn as there may be attempts from multiple proxies.
                    $self->warn("curl failed (". ($?>>8) ."): $errs\nCommand = $proc");
                    return 0; # Curl barfed, so we return.
                } else {
                    if ($CAF::Object::NoAction) {
                        $self->debug(1, "We have sucessfully pretended to retrieve a new copy of the file $fn");
                    } else {
                        $self->debug(1, "We seem to have sucessfully retrieved a new copy of the file $fn");
                    }
                    return 1;
                }
            } else {
                $self->debug(1, "Remote file is newer than acceptable ",
                             "threshold, or in the future; nothing retrieved");
                return 1;
            }
        } else {
            $self->debug(1, "Remote file is not newer than existing local copy, nothing retrieved");
            return 1;
        }
    } else {
        $self->debug(1, "Unable to obtain timestamp of remote file, nothing retrieved");
        return 0; # fail
    }
}

=pod

=back

=cut

1; #required for Perl modules
