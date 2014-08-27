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
###############################################################################

package NCM::Component::resolver;

#
# a few standard statements, mandatory for all components
#

use strict;
use Socket;
use NCM::Component;
use LC::File;
use LC::Check;
use LC::Process;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

##########################################################################
sub Configure {
##########################################################################
    my ($self,$config)=@_;

    my $path = "/software/components/resolver";
    if (!$config->elementExists($path)) {
        return 1;
    }
    my $inf = $config->getElement($path)->getTree;

    my @servers = ();
    my $host = ""; # The server we will use to test our change.
    foreach my $s (@{$inf->{servers}}) {
        if ($s =~ m[^(?:\d{1,3}\.){3}\d{1,3}$]) {
            # looks a bit like an ipv4 addr.
            push(@servers, $s);
            if (!$host) {
                $host = $s;
            }
        } else {
            my $addr = gethostbyname($s);
            if ($addr) {
                my $ip = inet_ntoa($addr);
                push(@servers, $ip);
                if (!$host) {
                    $host = $ip;
                }
            }
        }
    }
    if (!@servers) {
        $self->error("No DNS servers, not changing resolv.conf or configuring dnscache");
        return 0;
    }

    my @testservers = ();
    my $resolv = "";
    if ($inf->{dnscache}) {
        # If we are using dnscache the server we want to test is dnscache itself
        push(@testservers, "127.0.0.1");
        $resolv .= "nameserver 127.0.0.1\n";
    } else {
        @testservers = @servers;
        foreach my $srvr (@servers) {
            $resolv .= "nameserver $srvr\n";
        }
    }
    if ($inf->{search}) {
        $resolv .= "search " . join(" ", @{$inf->{search}}) . "\n";
    }

    my $servers_file = '/var/spool/dnscache/servers/@';
    my $old = "";
    if ($inf->{dnscache}) {
        $old = LC::File::file_contents($servers_file);
        $self->change_dnscache($inf, $servers_file, join("\n", @servers) . "\n");
    }

    # We also want to check that it's working, before
    # we commit to this.
    my $check = $self->check_dns_servers($host, @testservers);
    if (!$check) {
        $self->debug(1, "host resolution does not appear to be working");
        if ($inf->{dnscache}) {
            # We need to put the dnscache config back to the way it was
            $self->debug(1, "reverting dnscache config");
            $self->change_dnscache($inf, $servers_file, $old);
        }
        return 0;
    } else {
        $self->log("host resolution appears to be working");
    }

    my $ret = LC::Check::file("/etc/resolv.conf",
                              contents => $resolv,
                              owner => 'root',
                              group => 'root',
                              mode => '0444');
    if (defined $ret) {
        if ($ret > 0) {
            $self->log("updated resolv.conf");
        }
    } else {
        $self->error("failed to update resolv.conf: $!");
    }

    return 1;
}

sub check_dns_servers {
    my ($self, $host, @servers) = @_;

    $self->debug(1, "using $host to test our dns config");

    my $working_servers = 0;
    foreach my $testserver (@servers) {
        my $out = "";
        my $rc = LC::Process::execute(["/usr/bin/host", $host, $testserver],
                                      stderr => 'stdout',
                                      stdout => \$out);
        if (!$rc || $out =~ /timed out/) {
            $self->warn("Looking up $host on $testserver failed with output: $out");
        } else {
            $self->debug(1, "Looking up $host on $testserver succeeded");
            $working_servers += 1;
        }
    }

    if ($working_servers) {
        $self->debug(1, "$working_servers/" . @servers . " servers tested successfully");
        return 1;
    } else {
        $self->error("All servers failed testing, will not change resolv.conf");
        return 0;
    }
}

sub change_dnscache {
    my ($self, $inf, $servers_file, @servers) = @_;
    my $content = join("\n", @servers) . "\n";
    my $ret = LC::Check::file($servers_file,
                                contents => $content,
                                owner => 'root',
                                group => 'root',
                                mode  => '0444');
    if (defined $ret) {
        if ($ret == 0) {
            $self->log("$servers_file unchanged");
        } else {
            $self->log("updated $servers_file");

            my $errs = "";
            my $out= "";
            my $rc = LC::Process::execute(["/etc/init.d/dnscache", "restart" ], stderr => \$errs, stdout => \$out);
            $self->debug(5, "restart dnscache said: $out");
            if (!$rc) {
                $self->error("failed to restart dnscache: $errs");
                return 0;
            } else {
                $self->log("restarted dnscache");
            }
        }
    } else {
        $self->error("failed to update $servers_file: $!");
    }
}

1; #required for Perl modules
