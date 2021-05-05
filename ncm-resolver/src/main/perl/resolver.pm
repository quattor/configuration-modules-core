# ${license-info}
# ${developer-info}
# ${author-info}

package NCM::Component::resolver;

#
# a few standard statements, mandatory for all components
#

use strict;
use Socket;
use NCM::Component;
use LC::File;
use CAF::FileWriter;
use CAF::Process;
use EDG::WP4::CCM::CacheManager::Encode qw/BOOLEAN/;

use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

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

    # Configuration options
    if ($inf->{search}) {
        $resolv .= "search " . join(" ", @{$inf->{search}}) . "\n";
    }
    if ($config->elementExists("$path/options")) {
        my $options = $config->getElement("$path/options");
        while ($options->hasNextElement()) {
            my $entry = $options->getNextElement();
            my $name = $entry->getName();
            my $value = $entry->getValue();
            if ($entry->isType(BOOLEAN)) {
                $resolv .= "options $name\n";
            } else {
                $resolv .= "options $name:$value\n";
            }
        }
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
        $self->info("host resolution appears to be working");
    }

    my $fh = CAF::FileWriter->open("/etc/resolv.conf",
                                   owner => 'root',
                                   group => 'root',
                                   mode => '0444',
                                   log => $self,
        );
    print $fh $resolv;
    if ($fh->close()) {
        my $msg = $NoAction ? "Would update" : "Updated";
        $self->info("$msg resolv.conf");
    }

    return 1;
}

sub check_dns_servers {
    my ($self, $host, @servers) = @_;

    $self->debug(1, "using $host to test our dns config");

    my $working_servers = 0;
    foreach my $testserver (@servers) {
        my $proc = CAF::Process->new(["/usr/bin/host", $host, $testserver],
                                     log => $self,
            );
        my $out = $proc->output;
        if ($? || $out =~ /timed out/) {
            $self->warn("Looking up $host on $testserver failed with output: $out");
        } else {
            $self->debug(1, "Looking up $host on $testserver succeeded with output: $out");
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
    my $fh = CAF::FileWriter->new($servers_file,
                                  owner => 'root',
                                  group => 'root',
                                  mode  => '0444',
                                  log => $self,
        );
    print $fh $content;
    if ($fh->close()) {
        my $msg = $NoAction ? "Would have " : "";
        $self->info($msg . "updated $servers_file");

        my $errs = "";
        my $out = "";
        my $proc = CAF::Process->new(["/etc/init.d/dnscache", "restart"],
                                     stdout => \$out, stderr => \$errs,
                                     log => $self,
            );
        $self->debug(1, "restart dnscache said: $out");
        $proc->execute();
        if ($?) {
            $self->error("failed to restart dnscache: $errs");
            return 0;
        } else {
            $self->info($msg . "restarted dnscache");
        }
    } else {
        $self->verbose("$servers_file unchanged");
    }
}

1; #required for Perl modules
