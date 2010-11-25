# ${license-info}
# ${developer-info}
# ${author-info}

#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the EU DataGrid Software License.  You should
# have received a copy of the license with this program, and the license
# is published at http://eu-datagrid.web.cern.ch/eu-datagrid/license.html.
#
# THE FOLLOWING DISCLAIMER APPLIES TO ALL SOFTWARE CODE AND OTHER MATERIALS
# CONTRIBUTED IN CONNECTION WITH THIS PROGRAM.
#
# THIS SOFTWARE IS LICENSED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE AND ANY WARRANTY OF NON-INFRINGEMENT, ARE
# DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. THIS
# SOFTWARE MAY BE REDISTRIBUTED TO OTHERS ONLY BY EFFECTIVELY USING
# THIS OR ANOTHER EQUIVALENT DISCLAIMER AS WELL AS ANY OTHER LICENSE
# TERMS THAT MAY APPLY.
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################
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
                my $proc = CAF::Process->new(["kinit", "-k"], stderr => \$errs);
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


        my $success = 0;
        if (@proxyhosts && $inf->{files}->{$f}->{proxy}) {
            my $attempts = scalar @proxyhosts;
            while ($attempts--) {
                # take the head of the list and rotate to the end...
                # we do this in order to avoid continually trying a dead
                # proxy - once we've found one that works, we'll keep using it.
                my $proxy = shift @proxyhosts; 
                $success += $self->download(file => $file,
                                            href => $source,
                                            timeout => $inf->{timeout},
                                            proxy => $proxy,
                                            gssneg => $gss,
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
            if (!$self->download(file => $file,
                                 href => $source,
                                 timeout => $inf->{timeout},
                                 gssneg => $gss,
                                 min_age => $min_age)) {
                $self->error("failed to retrieve $source, skipping");
                next;
            }
        }
        $self->info("successfully processed file $file");
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
            if ($r > 0) {
                $self->log("updated $file");
            } elsif ($r < 0) {
                $self->error("failed to update perms/ownershup of $file");
	  }
	}

        my $cmd = $inf->{files}->{$f}->{post};
        if ($cmd) {
            my $errs = "";
            my $proc = CAF::Process->new([ $cmd, $file], stderr => \$errs);
            $proc->execute();
            if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                $self->error("post-process of $file gave errors: $errs");
            }
        }
    }

    return 0;
}

sub download {
    my ($self, %opts) = @_;
    my ($file, $source, $timeout, $proxy, $gssneg, $min_age);
    $file    = delete $opts{file};
    $source  = delete $opts{href};
    $timeout = delete $opts{timeout};
    $proxy   = delete $opts{proxy} || "";
    $gssneg  = delete $opts{gssneg} || 0;
    $min_age = delete $opts{min_age} || 0;

    $self->debug(1, "Processing file $file");

    if ($proxy) {
        $source =~ s{^([a-z]+)://([^/]+)/}{$1://$proxy/};
    }

    my @opts = (
                "-s", # quiet
                "-R", # timestamp based on remote URL
                "-o", $file, # output-file $file
                "-f", # fail on server error
                "--create-dirs",
               );

    if ($timeout) {
        push(@opts, "-m", $timeout);
    }

    if ($gssneg) {
        # If negotiate extension is required, then we'll
        # enabled and put in a dummy username/password.
        push(@opts, "--negotiate", "-u", "x:x");
    }

    # Get timestamp of any existing file, defaulting to zero if the file doesn't exist
    my $timestamp_existing = 0;
    if (-e $file) {
        $timestamp_existing  = (stat($file))[9];
    }

    my $timestamp_threshold = (time() - ($min_age * 60)); # Turn minutes into seconds and calculate the threshold that the remote timestamp must be below
    my $timestamp_remote    = LWP::UserAgent->new->head($source)->headers->last_modified(); # :D

    if ($timestamp_remote) {
        if ($timestamp_remote > $timestamp_existing) { # If local file doesn't exist, this still works
            if ($timestamp_remote <= $timestamp_threshold) { # Also prevents future files
                $self->debug(1, "running /usr/bin/curl " . join(" ", @opts) . " $source");

                my $errs = "";
                my $proc = CAF::Process->new([ "/usr/bin/curl", @opts, $source], stderr => \$errs);
                $proc->execute();
                if (!POSIX::WIFEXITED($?) || POSIX::WEXITSTATUS($?) != 0) {
                    $self->debug(1, "curl failed (" . ($?>>8) .")");
                    return 0; # Curl barfed, so we fail
                } else {
                    $self->debug(1, "We seem to have sucessfully downloaded a new copy of the file");
                    return 1;
                }
            }
            else {
                $self->debug(1, "Remote file is newer than acceptable threshold, or in the future, nothing downloaded");
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
