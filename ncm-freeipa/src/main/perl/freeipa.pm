#${PMpre} NCM::Component::${project.artifactId}${PMpost}
use base qw(NCM::Component);

use Readonly;
use NCM::Component::FreeIPA::Client;

use CAF::Reporter;

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

=head2 server

Configure server settings

=cut

sub server
{
    my ($self, $tree) = @_;

    my $dbglvl = $self->{LOGGER}->_rep_setup()->{$CAF::Reporter::DEBUGLV};

    # Only allow kerberos for now
    my $client = NCM::Component::FreeIPA::Client->new(
        $tree->{primary},
        log => $self,
        debugapi => defined($dbglvl) && $dbglvl >= 3, # API logging from debuglevel 3
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
            $reverse .= '.in-addr.arpa.' if ($reverse !~ /\.$/);
            $client->add_dnszone($reverse) if $reverse;
        }
    };

}

sub Configure
{

    my ($self, $config) = @_;

    my $tree = $config->getTree($self->prefix());

    $self->server($tree) if $tree->{server};

    return 1;
}

1; #required for Perl modules
