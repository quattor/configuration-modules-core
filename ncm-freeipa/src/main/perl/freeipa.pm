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

# Hold an instance of the client
my $client;

sub dns
{
    my ($self, $dns) = @_;

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

    return SUCCESS;
}

sub hosts
{
    my ($self, $hosts) = @_;

    foreach my $fqdn (sort keys %$hosts) {
        $client->add_host($fqdn, %{$hosts->{$fqdn}});
    };

    return SUCCESS;
}


sub services
{
    my ($self, $svcs) = @_;

    my $res = $client->do_one('host', 'find', '');
    # Flatten the results
    my @known_hosts = map {@{$_->{fqdn}}} @$res;
    $self->verbose("Service found ".(scalar @known_hosts)." known hosts");

    foreach my $svc (sort keys %$svcs) {
        $self->verbose("Service $svc");
        my $hosts = $svcs->{$svc}->{hosts};
        if($hosts) {
            $self->verbose("Service $svc ".(scalar @$hosts)." host patterns ", @$hosts);
            foreach my $pat (@$hosts) {
                $self->verbose("Service $svc ".(scalar @$hosts)." host patterns $pat @known_hosts");
                foreach my $host (grep {/$pat/} @known_hosts) {
                    $client->add_service_host($svc, $host);
                }
            }
        }
    }

    return SUCCESS;
}


sub users_groups
{
    my ($self, $users, $groups) = @_;

    # Add groups without members, so we can add primary
    foreach my $group (sort keys %$groups) {
        my %opts = %{$groups->{$group}};
        delete $opts{members};
        $client->add_group($group, %opts);
    }

    # Add users, do group->gidnumber translation
    foreach my $user (sort keys %$users) {
        my %opts = %{$users->{$user}};
        my $group = delete $opts{group};
        $opts{gidnumber} = $groups->{$group}->{gidnumber} if $group;
        $client->add_user($user, %opts);
    }

    # Add group members
    foreach my $group (sort keys %$groups) {
        my $members = $groups->{$group}->{members};
        $client->add_group_member($group, %$members) if $members;
    }

    return SUCCESS;
}

=head2 server

Configure server settings

=cut

sub server
{
    my ($self, $tree) = @_;

    my $dbglvl = $self->{LOGGER} ? $self->{LOGGER}->get_debuglevel() : 0;

    # Only allow kerberos for now
    $client = NCM::Component::FreeIPA::Client->new(
        $tree->{primary},
        log => $self,
        debugapi => defined($dbglvl) && $dbglvl >= $DEBUGAPI_LEVEL,
        );
    return if ! $client->{rc};

    return if ! $self->dns($tree->{server}->{dns});

    return if ! $self->hosts($tree->{server}->{hosts});

    return if ! $self->services($tree->{server}->{services});

    return if ! $self->users_groups($tree->{server}->{users}, $tree->{server}->{groups});

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
