#${PMpre} NCM::Component::${project.artifactId}${PMpost}
use base qw(NCM::Component);

use Readonly;
use NCM::Component::FreeIPA::Client;

use CAF::Object qw(SUCCESS);
use CAF::Reporter 16.2.1;

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

# API logging from debuglevel 3
Readonly my $DEBUGAPI_LEVEL => 3;

=head2 server

Configure server settings

=cut

sub server
{
    my ($self, $tree) = @_;

    my $dbglvl = $self->{LOGGER} ? $self->{LOGGER}->get_debuglevel() : 0;

    # Only allow kerberos for now
    my $client = NCM::Component::FreeIPA::Client->new(
        $tree->{primary},
        log => $self,
        debugapi => defined($dbglvl) && $dbglvl >= $DEBUGAPI_LEVEL,
        );
    return if ! $client->{rc};

    my $dns = $tree->{server}->{dns};
    if ($dns) {
        foreach my $name (sort keys %$dns) {
            # Add the name
            $client->add_dnszone($name);
            # If subnet, add it
            my $subnet = $dns->{$name}->{subnet};
            $client->add_dnszone($subnet) if $subnet;

            my $reverse = $dns->{$name}->{reverse};
            # If reverse, add it
            #   elsif autoreverse: derive from subnet
            if (! $reverse && $subnet && $dns->{$name}->{autoreverse}) {
                # For now very simplistic algorithm: only 8-bit masks
                my ($ip, $mask) = split('/', $subnet);
                if ($mask % 8 == 0) {
                    my @ips = split(/\./, $ip);
                    $reverse = join('.', reverse @ips[0..$mask/8-1]);
                } else {
                    $self->verbose("Autoreverse is unable to determine the reverse for zone $name and subnet $subnet");
                }
            };
            # Append the inaddr.arpa.
            if ($reverse) {
                $reverse .= '.in-addr.arpa.' if ($reverse !~ /\.$/);
                $client->add_dnszone($reverse) ;
            };
        }
    };

    my $hosts = $tree->{server}->{hosts};
    if ($hosts) {
        foreach my $fqdn (sort keys %$hosts) {
            $client->add_host($fqdn, %{$hosts->{$fqdn}});
        };
    };

    return SUCCESS;
}


sub Configure
{

    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());

    $self->server($tree) if $tree->{server};

    return 1;
}

1; #required for Perl modules
