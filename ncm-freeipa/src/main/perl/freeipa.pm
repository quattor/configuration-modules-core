#${PMpre} NCM::Component::${project.artifactId}${PMpost}
use base qw(NCM::Component CAF::Path);

use Readonly;
use NCM::Component::FreeIPA::Client;
use NCM::Component::FreeIPA::NSS;

use CAF::Object qw(SUCCESS);
use CAF::Reporter 16.2.1;
use CAF::Kerberos;
use EDG::WP4::CCM::Element qw(unescape);
use File::Basename;

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

# API logging from debuglevel 3
Readonly my $DEBUGAPI_LEVEL => 3;
Readonly::Array my @GET_KEYTAB => qw(/usr/sbin/ipa-getkeytab);

Readonly my $NSSDB => '/etc/nssdb.quattor';

# packages to install with yum for dependencies
Readonly::Array our @CLI_YUM_PACKAGES => qw(
    ncm-freeipa-${no-snapshot-version}-${RELEASE}
    nss_ldap
    ipa-client
    nss-tools
    openssl
);

# Fixed settings for he "quattor" host certificate
# Retrieve the certificate from the host keytab
Readonly my %QUATTOR_CERTIFICATE => {
    owner => 'root',
    group => 'root',
    mode => 0400,
    key => '/etc/pki/tls/private/quattor.key',
    certmode => 0444,
    cert => '/etc/pki/tls/certs/quattor.pem',
};

Readonly my $IPA_ROLE_CLIENT => 'client';
Readonly my $IPA_ROLE_SERVER => 'server';
Readonly my $IPA_ROLE_AII => 'aii';

# Hold an instance of the client
my $_client;

# Current host FQDN
my $_fqdn;

# server config
sub dns
{
    my ($self, $dns) = @_;

    foreach my $name (sort keys %$dns) {
        # Add the name
        $_client->add_dnszone($name);
        # If subnet, add it
        my $subnet = $dns->{$name}->{subnet};
        $_client->add_dnszone($subnet) if $subnet;

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
            $_client->add_dnszone($reverse) ;
        };
    }

    return SUCCESS;
}

# server config
sub hosts
{
    my ($self, $hosts) = @_;

    foreach my $hn (sort keys %$hosts) {
        $_client->add_host($hn, %{$hosts->{$hn}});
    };

    return SUCCESS;
}

# server config
sub services
{
    my ($self, $svcs) = @_;

    my @known_hosts;
    if ($svcs) {
        my $res = $_client->do_one('host', 'find', '');
        # Flatten the results
        @known_hosts = map {@{$_->{fqdn}}} @$res;
        $self->verbose("Service found ".(scalar @known_hosts)." known hosts");
    }

    foreach my $svc (sort keys %$svcs) {
        $self->verbose("Service $svc");
        my $hosts = $svcs->{$svc}->{hosts};
        if($hosts) {
            $self->verbose("Service $svc ".(scalar @$hosts)." host patterns ", @$hosts);
            foreach my $pat (@$hosts) {
                $self->verbose("Service $svc ".(scalar @$hosts)." host patterns $pat @known_hosts");
                foreach my $host (grep {/$pat/} @known_hosts) {
                    $_client->add_service_host($svc, $host);
                }
            }
        }
    }

    return SUCCESS;
}

# server config
sub users_groups
{
    my ($self, $users, $groups) = @_;

    # Add groups without members, so we can add primary
    foreach my $group (sort keys %$groups) {
        my %opts = %{$groups->{$group}};
        delete $opts{members};
        $_client->add_group($group, %opts);
    }

    # Add users, do group->gidnumber translation
    foreach my $user (sort keys %$users) {
        my %opts = %{$users->{$user}};
        my $group = delete $opts{group};
        $opts{gidnumber} = $groups->{$group}->{gidnumber} if $group;
        $_client->add_user($user, %opts);
    }

    # Add group members
    foreach my $group (sort keys %$groups) {
        my $members = $groups->{$group}->{members};
        $_client->add_group_member($group, %$members) if $members;
    }

    return SUCCESS;
}

=head2 server

Configure server settings

=cut

sub server
{
    my ($self, $tree) = @_;

    return if ! $self->dns($tree->{server}->{dns});

    return if ! $self->hosts($tree->{server}->{hosts});

    return if ! $self->services($tree->{server}->{services});

    return if ! $self->users_groups($tree->{server}->{users}, $tree->{server}->{groups});

    return SUCCESS;
}


# client config
sub service_keytab
{
    my ($self, $tree) = @_;

    foreach my $fn (sort keys %{$tree->{keytabs}}) {
        my $filename = unescape($fn);
        my $serv = $tree->{keytabs}->{$fn};

        my $directory = dirname($filename);
        if(! $self->directory_exists($directory)) {
            $self->verbose("Creating directory $directory");
            $self->directory($directory);
        }

        if($self->file_exists($filename)) {
            $self->verbose("Keytab $filename already exists");
        } else {
            my $principal = $serv->{service};
            # Add fqdn as
            $principal .= "/$_fqdn" if ($principal !~ m{/});

            # Retrieve keytab (what if already exists?)
            my $proc = CAF::Process->new([@GET_KEYTAB,
                                          '-s', $tree->{primary},
                                          '-p', $principal,
                                          '-k', $filename,
                                         ], log => $self);
            my $output = $proc->output();
            if ($?) {
                $self->error("Failed to retrieve keytab $filename for principal $principal (proc $proc): $output");
            } else {
                $self->verbose("Successfully retrieved keytab $filename: $output");
            }
        }

        # Set permissions/ownership
        my %opts = map {$_ => $serv->{$_}} qw(owner group mode);
        $self->status($filename, %opts);
    }

    return SUCCESS;
}

# client config
sub certificates
{
    my ($self, $tree) = @_;

    # One NSSDB for all?
    my $nss = NCM::Component::FreeIPA::NSS->new(
        $NSSDB,
        realm => $tree->{realm},
        log => $self,
        );

    if($nss->setup()) {
        # TODO: do we always need to readd it?
        if ($nss->add_cert_ca()) {
            $self->verbose("CA cert added");
        } else {
            $self->error("Failed to add CA cert: $nss->{fail}");
            return;
        };

        foreach my $nick (sort keys %{$tree->{certificates}}) {
            # How do we renew the certificates?
            my $cert = $tree->{certificates}->{$nick};
            if ($nss->has_cert($nick)) {
                $self->verbose("Found certificate for nick $nick");
            } else {
                my $initcrt = "$nss->{workdir}/init_nss_$nick.crt";
                my $msg = "Initial NSS certificate for nick $nick (temp $initcrt)";
                # Make request csr
                my $csr = $nss->make_cert_request($_fqdn, $nick);
                if ($csr &&
                    $nss->ipa_request_cert($csr, $initcrt, $_fqdn, $_client) && # Get cert via IPA
                    $nss->add_cert($nick, $initcrt) # Add to NSSDB
                    ) {
                    $self->verbose("$msg added");
                } else {
                    $self->error("$msg failed: $nss->{fail}");
                    return;
                };
            }

            foreach my $type (qw(cert key)) {
                my $fn = $cert->{$type};
                next if ! defined($fn);

                my $modeattr = ($type eq 'cert' ? $type : '').'mode';
                my %opts = map {$_ => $cert->{$_}} (qw(owner group));
                $opts{mode} = $cert->{$modeattr} if defined($cert->{$modeattr});

                my $msg = "$type file $fn for nick $nick";
                if ($self->file_exists($fn)) {
                    $self->verbose("Found existing $msg");
                } else {
                    # Extract with get_cert
                    if ($nss->get_cert_or_key($type, $nick, $fn, %opts)) {
                        $self->verbose("Extracted $msg");
                    } else {
                        $self->error("Failed to extract $msg: $nss->{fail}");
                        return;
                    }
                }
            }
        }
        return SUCCESS;
    } else {
        $self->error("NSSDB setup failed: $nss->{fail}");
    }

    return;
}

=head2 server

Configure server settings

=cut

sub client
{
    my ($self, $tree) = @_;

    $self->service_keytab($tree) if $tree->{keytabs};

    if ($tree->{quattorcert}) {
        $self->verbose("Add quattor certificate (and key) in $QUATTOR_CERTIFICATE{certificate}");
        $tree->{certificates}->{quattor} = \%QUATTOR_CERTIFICATE;
    };

    $self->certificates($tree) if $tree->{certificates};

    return SUCCESS;
}

# ugly, but convenient: set class-variable _fqdn though named options
#    config: from a configuration instance (and /system/network)
#    fqdn: set this as fqdn
sub set_fqdn
{
    my ($self, %opts) = @_;

    if ($opts{fqdn}) {
        $_fqdn = $opts{fqdn};
    } elsif ($opts{config}) {
        my $config = $opts{config};

        my $network = $config->getTree('/system/network');
        $_fqdn = "$network->{hostname}.$network->{domainname}";
    }

    return $_fqdn;
}

# ugly, but convenient: set class-variable IPA client instance
# tree is the config hashref, requires at least a primary key
sub set_ipa_client
{
    my ($self, $tree, %opts) = @_;

    # Default principal / keytab; suffcient for (default) client
    my $principal = "host/$_fqdn";
    my $keytab = '/etc/krb5.keytab';

    my $role = $opts{role};
    if ($role) {
        my $role_principal = $tree->{principals} && $tree->{principals}->{$role};
        if ($role_principal) {
            $principal = $role_principal->{principal};
            $keytab = $role_principal->{keytab};
            $self->verbose("IPA client with role $role principal $principal keytab $keytab");
        } elsif ($opts{role} eq $IPA_ROLE_CLIENT) {
            $self->verbose("IPA client with role $role and default principal $principal keytab $keytab");
        } else {
            return $self->fail("IPA client with role $role but no principal/keytab specified");
        };
    };

    my $dbglvl = $self->{LOGGER} ? $self->{LOGGER}->get_debuglevel() : 0;

    my $krb = CAF::Kerberos->new(
        principal => $principal,
        keytab => $keytab,
        log => $self,
        );
    return if(! defined($krb->get_context(usecred => 1)));

    # set environment to temporary credential cache
    # temporary cache is cleaned-up during destroy of $krb
    local %ENV;
    $krb->update_env(\%ENV);

    # Only allow kerberos for now
    $_client = NCM::Component::FreeIPA::Client->new(
        $tree->{primary},
        log => $self,
        debugapi => defined($dbglvl) && $dbglvl >= $DEBUGAPI_LEVEL,
        );

    return $_client;
}

# Return IPA client class variable (for subclassing)
sub get_ipa_client
{
    my ($self) = @_;

    return $_client;
}

# Perform relevant part in separate method, so we can subclass this component
# in a standalone bootstrap module
sub _configure
{
    my ($self, $tree) = @_;

    my $role = $tree->{server} ? $IPA_ROLE_SERVER : $IPA_ROLE_CLIENT;

    $self->set_ipa_client($tree, role => $role);

    if ($_client->{rc}) {
        $self->server($tree) if $tree->{server};

        $self->client($tree);

        return SUCCESS;
    } else {
        $self->error("Failed to obtain FreeIPA Client: $_client->{error}");
    };
}

sub Configure
{

    my ($self, $config) = @_;

    $self->set_fqdn(config => $config);

    my $tree = $config->getTree($self->prefix());

    $self->_configure($tree);

    return 1;
}


# AII post_reboot hook
# TODO: requesting a OTP, to be used withing max window seconds
sub post_reboot
{
    my ($self, $config, $path) = @_;

    $self->set_fqdn(config => $config);
    my $tree = $config->getTree($self->prefix());

    $self->set_ipa_client($tree, role => $IPA_ROLE_AII);

    my $hook = $config->getTree($path);

    my $network = $config->getTree('/system/network');

    # Add host (should be ok if already exists)
    $_client->add_host($_fqdn, %{$tree->{host}});

    # Mod host to get OTP (should give an error if not allowed)
    my $otp = $_client->host_passwd($_fqdn);
    if ($otp) {
        my $yum_packages = join(" ", @CLI_YUM_PACKAGES);

        my $domain = $tree->{domain} || $network->{domainname};

        # Is optional, but we use the template value; not the CLI default
        my $quattorcert = $tree->{quattorcert} ? 1 : 0;

        print <<EOF;
# freeipa KS post_reboot
echo "begin freeipa post_reboot"

yum -c /tmp/aii/yum/yum.conf -y install $yum_packages

PERL5LIB=/usr/lib/perl perl -MNCM::Component::FreeIPA::CLI -w -e install -- --realm $tree->{realm} --primary $tree->{primary} --otp $otp --domain $domain --fqdn $_fqdn --quattorcert $quattorcert

echo "end freeipa post_reboot"

EOF

    } else {
        $self->error("freeipa post_reboot: no OTP for $_fqdn");
    }

    return 1;
}

# AII remove hook
sub remove
{
    my ($self, $config, $path) = @_;

    $self->set_fqdn(config => $config);
    my $tree = $config->getTree($self->prefix());

    $self->set_ipa_client($tree, role => $IPA_ROLE_AII);

    my $hook = $config->getTree($path);

    if ($hook->{remove}) {
        $self->debug(1, "freeipa remove hook: remove host $_fqdn");
        $_client->remove_host($_fqdn);
    } elsif ($hook->{disable}) {
        $self->debug(1, "freeipa remove hook: disable host $_fqdn");
        $_client->disable_host($_fqdn);
    } else {
        $self->debug(1, "freeipa remove hook: nothing to do for $_fqdn");
    }

    return 1;
}


1; #required for Perl modules
