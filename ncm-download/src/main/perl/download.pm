# ${license-info}
# ${developer-info}
# ${author-info}

#
# download - Morgan Stanley ncm-download component
#
# Download files during configuration (e.g. via web)
#
###############################################################################

package NCM::Component::download;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use File::Temp qw(tempdir);
use CAF::Process qw(execute);
use POSIX;
use LWP::UserAgent;
use HTTP::Request::Common;

$NCM::Component::download::NoActionSupported = 1;

# Just in case...
$ENV{PATH} = "$ENV{PATH}:/usr/kerberos/bin";

sub prefix {
    my ($self) = @_;
    return "/software/components/download";
}


##########################################################################
sub Configure {
##########################################################################
    my ($self,$config)=@_;

    my $prefix = $self->prefix;

    if (!$config->elementExists("$prefix")) {
        return 0;
    }

    my $inf = $config->getElement("$prefix")->getTree;
    my $defserver = "";
    if (exists $inf->{server}) {
        $defserver = $inf->{server};
    }
    my $defproto = "";
    if (exists $inf->{proto}) {
        $defproto = $inf->{proto};
    }

    my @proxyhosts = ();
    if (exists $inf->{proxyhosts} && ref($inf->{proxyhosts}) eq 'ARRAY') {
        @proxyhosts = @{$inf->{proxyhosts}};
    }

    my $cached_gss = undef;
    foreach my $f (keys %{$inf->{files}}) {
        my $file = $self->unescape($f);
        my $source = $inf->{files}->{$f}->{href};
        my $gss = 0;
        if (exists $inf->{files}->{$f}->{gssapi} && $inf->{files}->{$f}->{gssapi}) {
            if (!$cached_gss) {
                $cached_gss = tempdir("ncm-download-XXXXXX", TMPDIR => 1, CLEANUP => 1);
                $self->debug(1, "storing kerberos credentials in $cached_gss");
                $ENV{KRB5CCNAME} = "FILE:$cached_gss/host.tkt";
                # Assume "kinit" is in the PATH.
                my $errs = "";
                my $proc = CAF::Process->new(["kinit", "-k"], stderr => \$errs,
                        log => $self);
                $proc->execute();
                if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                    $self->error("could not get GSSAPI credentials: $errs");
                    return 0;
                }
            }
            $gss = $cached_gss;
        }

        if ($source !~ m{^[a-z]+://.*}) {
            # an incomplete URL... let's add defaults
            if ($source !~ m{^/}) {
                $source = "/$source";
            }
            if ($source !~ m{^//}) {
                my $server = $defserver;
                if (exists $inf->{files}->{$f}->{server}) {
                    $server = $inf->{files}->{$f}->{server};
                }
                if (!$server) {
                    $self->error("$file requested but no server, ignoring");
                    next;
                }
                $source = "//$server$source";
            }
            if ($source =~ m{^//}) {
                # server specified, but no proto
                my $proto = $defproto;
                if (exists $inf->{files}->{$f}->{proto}) {
                    $proto = $inf->{files}->{$f}->{proto};
                }
                if (!$proto) {
                    $self->error("$file requested but no proto, ignoring");
                    next;
                }
                $source = "$proto:$source";
            }
        }

        my $min_age = 0;
        if (exists $inf->{files}->{$f}->{min_age}) {
            $min_age = $inf->{files}->{$f}->{min_age};
        }

	my $timeout = $inf->{files}->{$f}->{timeout};
	$timeout = $inf->{timeout} unless defined($timeout);

        my $success = 0;
        if (@proxyhosts && $inf->{files}->{$f}->{proxy}) {
            my $attempts = scalar @proxyhosts;
            while ($attempts--) {
                # take the head off the list and rotate to the end...
                # we do this in order to avoid continually trying a dead
                # proxy - once we've found one that works, we'll keep using it.
                my $proxy = shift @proxyhosts;
                $self->debug(3, "Trying proxy $proxy");
                $success += $self->download(
                    file => $file,
                    href => $source,
                    timeout => $timeout,
                    head_timeout => $inf->{head_timeout},
                    proxy => $proxy,
                    gssneg => $gss,
                    cacert => $inf->{files}->{$f}->{cacert},
                    capath => $inf->{files}->{$f}->{capath},
                    cert => $inf->{files}->{$f}->{cert},
                    key =>  $inf->{files}->{$f}->{key},
                    min_age => $min_age);
                if ($success) {
                    @proxyhosts = ($proxy, @proxyhosts);
                    last;
                } else {
                    @proxyhosts = (@proxyhosts, $proxy);
                }
            }
            if (!$success) {
                $self->warn("failed to retrieve $source from any proxies, using original");
            }
        }
        if (!$success) {
            if (!$self->download(
                    file => $file,
                    href => $source,
                    timeout => $inf->{timeout},
                    gssneg => $gss,
                    cacert => $inf->{files}->{$f}->{cacert},
                    capath => $inf->{files}->{$f}->{capath},
                    cert => $inf->{files}->{$f}->{cert},
                    key =>  $inf->{files}->{$f}->{key},
                    min_age => $min_age)) {
                $self->error("failed to retrieve $source, skipping");
                next;
            }
        }
        my @opts = ();
        if (exists $inf->{files}->{$f}->{perm}) {
            push(@opts, 'mode' => $inf->{files}->{$f}->{perm});
        }
        if (exists $inf->{files}->{$f}->{owner}) {
            push(@opts, 'owner' => $inf->{files}->{$f}->{owner});
        }
        if (exists $inf->{files}->{$f}->{group}) {
            push(@opts, 'group' => $inf->{files}->{$f}->{group});
        }
        if (@opts) {
            my $r = LC::Check::status($file, @opts);
            # $r == 0 means there was no change
            if ($r > 0) {
                $self->log("updated $file to ", join(' ', @opts));
            } elsif ($r < 0) {
                $self->error("failed to update perms/ownership of $file to ". join(' ', @opts));
            }
        }

        my $cmd = $inf->{files}->{$f}->{post};
        if ($cmd) {
            my $errs = "";
            my $proc = CAF::Process->new([ $cmd, $file], stderr => \$errs,
                                         log => $self);
            $proc->execute();
            if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                $self->error("post-process of $file gave errors: $errs");
            }
        }
        $self->info("successfully processed file $file");
    }
    return 0;
}

sub get_head
{
    my ($self, $source, %opts) = @_;
    
    # LWP should use Net::SSL (provided with Crypt::SSLeay)
    # and Net::SSL doesn't support hostname verify
    local $ENV{'PERL_NET_HTTPS_SSL_SOCKET_CLASS'} = 'Net::SSL';
    local $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

    local $ENV{'HTTPS_CERT_FILE'} = $opts{cert} if exists($opts{cert});
    local $ENV{'HTTPS_KEY_FILE'} = $opts{key} if (exists($opts{key}));
    local $ENV{'HTTPS_CA_FILE'} = $opts{cacert} if (exists($opts{cacert}));
    local $ENV{'HTTPS_CA_DIR'} = $opts{capath} if (exists($opts{capath}));

    my $lwp = LWP::UserAgent->new;
    $lwp->timeout($opts{head_timeout}) if (defined($opts{head_timeout}));
    return $lwp->head($source);
}

sub download {
    my ($self, %opts) = @_;
    my ($file, $source, $timeout, $proxy, $gssneg, $min_age,
    $cacert, $capath, $cert, $key);
    $source  = $opts{href};
    $timeout = $opts{timeout};
    $proxy   = $opts{proxy} || "";
    $gssneg  = $opts{gssneg} || 0;
    $min_age = $opts{min_age} || 0;
    $cacert  = $opts{cacert};
    $capath  = $opts{capath};
    $key     = $opts{key};
    $cert    = $opts{cert};

    $self->debug(1, "Processing file $opts{file} from $source");

    my @cmd = (qw(/usr/bin/curl -s -R -f --create-dirs -o), $opts{file});

    if ($proxy) {
        $source =~ s{^([a-z]+)://([^/]+)/}{$1://$proxy/};
    }

    if ($timeout) {
        push @cmd, ("-m", $timeout);
    }

    if ($gssneg) {
        # If negotiate extension is required, then we'll
        # enabled and put in a dummy username/password.
        push @cmd, qw(--negotiate -u x:x);
    }

    if ($key) {
        push @cmd, ("--key", $key);
    }

    if ($cacert) {
        push @cmd, ("--cacert", $cacert);
    }

    if ($capath) {
        push @cmd, ("--capath", $capath);
    }

    if ($cert) {
        push @cmd, ("--cert", $cert);
    }

    push @cmd, $source;

    # Get timestamp of any existing file, defaulting to zero if the
    # file doesn't exist
    my $timestamp_existing = 0;
    if (-e $opts{file}) {
        $timestamp_existing  = (stat($opts{file}))[9];
    }

    # Turn minutes into seconds and calculate the threshold that the remote timestamp must be below
    my $timestamp_threshold = (time() - ($min_age * 60));
    my $timestamp_remote    = $self->get_head($source, %opts)->headers->last_modified(); # :D>;
    if ($timestamp_remote) {
        if ($timestamp_remote > $timestamp_existing) { # If local file doesn't exist, this still works
            if ($timestamp_remote <= $timestamp_threshold) { # Also prevents future files
                my $proc = CAF::Process->new(\@cmd, stderr => \my $errs, log => $self);
                $proc->execute();
                if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                    # Only warn as there may be attempts from multiple proxies.
                    $self->warn("curl failed (". ($?>>8) ."): $errs\nCommand = ". join(' ', @cmd));
                    return 0; # Curl barfed, so we return.
                } else {
                    if ($NoAction) {
                        $self->debug(1, "We have sucessfully pretended to download a new copy of the file");
                    } else {
                        $self->debug(1, "We seem to have sucessfully downloaded a new copy of the file");
                    }
                    return 1;
                }
            }
            else {
                $self->debug(1, "Remote file is newer than acceptable ",
                    "threshold, or in the future, nothing downloaded");
                return 1;
            }
        }
        else {
            $self->debug(1, "Remote file is not newer than existing local copy, nothing downloaded");
            return 1;
        }
    }
    else {
        $self->debug(1, "Unable to obtain timestamp of remote file, nothing downloaded");
        return 0; # fail
    }
}

1; #required for Perl modules
