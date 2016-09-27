#${PMpre} NCM::Component::download${PMpost}

use parent qw(NCM::Component CAF::Path);

our $EC = LC::Exception::Context->new->will_store_all;

use File::Temp qw(tempdir);
use CAF::Process;
use POSIX;

use LWP::UserAgent;
use LWP::Authen::Negotiate;

use EDG::WP4::CCM::Element qw(unescape);
use CAF::Object qw(SUCCESS);

$NCM::Component::download::NoActionSupported = 1;

# Hold the credential cache location / KRB5CCNAME value
my $_gss_tmpdir;
my $_cached_gss;

sub get_gss_token
{
    my $self = shift;

    # Return module wide cache value
    return $_cached_gss if $_cached_gss;

    $_gss_tmpdir = tempdir("ncm-download-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    $self->debug(1, "storing kerberos credentials in $_gss_tmpdir");

    my $ccache = "FILE:$_gss_tmpdir/host.tkt";
    local $ENV{KRB5CCNAME} = $ccache;

    # Just in case...
    local $ENV{PATH} = "$ENV{PATH}:/usr/kerberos/bin";

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
                unshift @$proxyhosts, $proxy;
                last;
            } else {
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

    # LWP should use Net::SSL (provided with Crypt::SSLeay)
    # and Net::SSL doesn't support hostname verify
    local $ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';
    local $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

    local $ENV{'HTTPS_CERT_FILE'} = $opts{cert} if $opts{cert};
    local $ENV{'HTTPS_KEY_FILE'} = $opts{key} if $opts{key};
    local $ENV{'HTTPS_CA_FILE'} = $opts{cacert} if $opts{cacert};
    local $ENV{'HTTPS_CA_DIR'} = $opts{capath} if $opts{capath};

    # Required for LWP::Authen::Negotiate
    local $ENV{KRB5CCNAME} = $opts{gss_ccache} if $opts{gss_ccache};

    my $lwp = LWP::UserAgent->new;
    $lwp->timeout($opts{head_timeout}) if (defined($opts{head_timeout}));
    my $head = $lwp->head($source);

    return $head->headers->last_modified();
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

    local $ENV{KRB5CCNAME};
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

1; #required for Perl modules
