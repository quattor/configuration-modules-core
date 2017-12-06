#${PMcomponent}
use base qw(NCM::Component CAF::Path);

=head1 DESCRIPTION

ncm-freeipa provides support for FreeIPA configuration for

=over

=item server: add users, groups, services

=item client: retrieve keytabs and certificates

=item initialisation: get started n an already deployed host

=item AII: add initialisation in kickstart and support removal

=back

=head2 Server

On the server, create a keytab for the quattor-server user
    kinit admin

    uidadmin=`ipa user-show admin |grep UID: |sed "s/UID://;s/ //g;"`
    gidadmin=`ipa user-show admin |grep GID: |sed "s/GID://;s/ //g;"`
    # keep random password; it's already expired
    ipa user-add quattor-server --first=server --last=quattor --random --uid=$(($uidadmin+1)) --gidnumber=$(($gidadmin+1))
    kdestroy
    # use expired random password; and pick new random password (new password is not relevant)
    kinit quattor-server
    kdestroy

    kinit admin
    ipa role-add "Quattor server"
    for priv in "Host Administrators" "DNS Administrators" "Group Administrators" "Service Administrators" "User Administrators"; do
        ipa role-add-privilege "Quattor server" --privileges="$priv"
    done
    ipa role-add-member --users=quattor-server "Quattor server"


    # use -r option to retrieve existing keytab (e.g. from another ipa server)
    ipa-getkeytab -p quattor-server -k /etc/quattor-server.keytab -s ipaserver.example.com

Use these with ncm-freeipa on the server.

    prefix "/software/components/freeipa/principals/server";
    "principal" = "quattor-server";
    "keytab" = "/etc/quattor-server.keytab";

(Do not retrieve a keytab for the admin user;
it resets the admin password).

=head2 AII

The AII hooks act on behalf of the host it is going to setup, so
any of those principals cannot be used. Instead we use a fixed
AII principal and keytab.

First we need to add a user with appropriate privileges
    kinit admin

    uidadmin=`ipa user-show admin |grep UID: |sed "s/UID://;s/ //g;"`
    gidadmin=`ipa user-show admin |grep GID: |sed "s/GID://;s/ //g;"`
    # keep random password; it's already expired
    ipa user-add quattor-aii --first=aii --last=quattor --random --uid=$(($uidadmin+2)) --gidnumber=$(($gidadmin+2))
    kdestroy
    # use expired random password; and pick new random password (new password is not relevant)
    kinit quattor-aii
    kdestroy

    kinit admin
    ipa role-add "Quattor AII"
    ipa role-add-privilege "Quattor AII" --privileges="Host Administrators"
    ipa role-add-member --users=quattor-aii "Quattor AII"

On the AII host (assuming the host is already added to IPA)
    kinit admin
    # use -r option to retrieve existing keytab (e.g. from another AII server)
    ipa-getkeytab -p quattor-aii -k /etc/quattor-aii.keytab -s ipaserver.example.com
    kdestroy


(If you have granted the host principal the rights to retrieve the quattor-aii keytab,
you can add in the template of the AII host
    prefix "/software/components/freeipa/principals/aii";
    "principal" = "quattor-aii";
    "keytab" = "/etc/quattor-aii.keytab";
)

=head2 Missing

=over

=item role / privileges

=item retrieve use keytabs

=item AII principal/keytab via config file

=back

=head1 Methods

=cut

use Readonly;
use NCM::Component::FreeIPA::Client;
use NCM::Component::FreeIPA::NSS;

use CAF::Object qw(SUCCESS);
use CAF::Reporter 16.2.1;
use CAF::Kerberos;
use EDG::WP4::CCM::Path qw(unescape);
use File::Basename;

our $EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::${project.artifactId}::NoActionSupported = 1;

# API logging from debuglevel 3
Readonly my $DEBUGAPI_LEVEL => 3;
Readonly::Array my @GET_KEYTAB => qw(/usr/sbin/ipa-getkeytab);

# packages to install with yum for dependencies
Readonly::Array our @CLI_YUM_PACKAGES => qw(
    ncm-freeipa
    nss-pam-ldapd
    ipa-client
    nss-tools
    openssl
);

Readonly my $IPA_BASEDIR => '/etc/ipa';
Readonly our $IPA_QUATTOR_BASEDIR => "$IPA_BASEDIR/quattor";

Readonly my $NSSDB => "$IPA_QUATTOR_BASEDIR/nssdb";

# Fixed settings for the host certificate
# Retrieve the certificate for the host DN
Readonly my $HOST_CERTIFICATE_NICK => 'host';
Readonly my %HOST_CERTIFICATE => {
    owner => 'root',
    group => 'root',
    mode => oct(400),
    key => "$IPA_QUATTOR_BASEDIR/keys/host.key",
    certmode => oct(444),
    cert => "$IPA_QUATTOR_BASEDIR/certs/host.pem",
};

Readonly my $IPA_ROLE_CLIENT => 'client';
Readonly my $IPA_ROLE_SERVER => 'server';
Readonly my $IPA_ROLE_AII => 'aii';

# TODO: configure via configfile
Readonly my $IPA_DEFAULT_AII_PRINCIPAL => 'quattor-aii';
Readonly my $IPA_DEFAULT_AII_KEYTAB => '/etc/quattor-aii.keytab';

# Filename that indicates if FreeIPA was already initialised
Readonly my $IPA_FILE_INITIALISED => "$IPA_BASEDIR/ca.crt";

# Hold an instance of the client
my $_client;

# Hold a Kerberos instance
my $_krb;

# Current host FQDN
# Warning: This is not config-safe (e.g. in AII), (re)set upon each API call
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
        my $res = $_client->do_one('host', 'find', '', sizelimit => 0);
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

        my $principal = $serv->{service};
        # Add fqdn when hostname is missing
        $principal .= "/$_fqdn" if ($principal !~ m{/});

        my $has_keytab = $_client->service_has_keytab($principal);

        if($self->file_exists($filename) && $has_keytab) {
            $self->verbose("Keytab $filename already exists");
        } else {
            my $args = [@GET_KEYTAB,
                        '-s', $tree->{primary},
                        '-p', $principal,
                        '-k', $filename];

            if ($has_keytab) {
                $self->verbose("A keytab for principal $principal exists elsewhere, retrieving a copy");
                # without -r, a new keytab will be created, rendering any other copies useless
                push(@$args, '-r');
            }

            # set environment to temporary credential cache
            # temporary cache is cleaned-up during destroy of $krb
            local %ENV;
            $_krb->update_env(\%ENV);

            # Retrieve keytab (what if already exists?)
            my $proc = CAF::Process->new($args, log => $self);
            my $output = $proc->output();
            if ($?) {
                $self->error("Failed to retrieve keytab $filename for principal $principal (proc $proc): $output");
            } else {
                $self->info("Successfully retrieved keytab $filename: $output");
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
    my %opts = (
        realm => $tree->{realm},
        log => $self,
        # Keep this last
        %{$tree->{nss} || {}}
    );

    my $nss = NCM::Component::FreeIPA::NSS->new($NSSDB, %opts);

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
            if ($nss->has_cert($nick, $_client)) {
                $self->verbose("Found NSS certificate for nick $nick");
            } else {
                my $initcrt = "$nss->{workdir}/init_nss_$nick.crt";
                my $msg = "Initial NSS certificate for nick $nick (temp $initcrt)";
                # Make request csr
                my $csr = $nss->make_cert_request($_fqdn, $nick);
                if ($csr &&
                    $nss->ipa_request_cert($csr, $initcrt, $_fqdn, $_client) && # Get cert via IPA
                    $nss->add_cert($nick, $initcrt) # Add to NSSDB
                    ) {
                    $self->info("$msg added");
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
                    # To hard to reverify key/cert; this is local anyway
                    $self->verbose("Found existing $msg; reextracting it from NSS anyway");
                }

                # Extract with get_cert
                if ($nss->get_cert_or_key($type, $nick, $fn, %opts)) {
                    $self->info("Extracted $msg");
                } else {
                    $self->error("Failed to extract $msg: $nss->{fail}");
                    return;
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

    if ($tree->{hostcert}) {
        # add it, preserve existing host settings
        $self->verbose("Add host certificate configuration with nick $HOST_CERTIFICATE_NICK (cert file $HOST_CERTIFICATE{cert})");
        $tree->{certificates}->{$HOST_CERTIFICATE_NICK} = {} if ! $tree->{certificates}->{$HOST_CERTIFICATE_NICK};
        my $hcert = $tree->{certificates}->{$HOST_CERTIFICATE_NICK};
        foreach my $k (sort keys %HOST_CERTIFICATE) {
            $hcert->{$k} = $HOST_CERTIFICATE{$k} if ! defined($hcert->{$k});
        };
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
sub _set_ipa_client
{
    my ($self, $tree, %opts) = @_;

    # Default principal / keytab; suffcient for (default) client
    my $principal = "host/$_fqdn";
    my $keytab = '/etc/krb5.keytab';

    my $role = $opts{role};
    if ($role) {
        my $role_principal = $tree->{principals} && $tree->{principals}->{$role};
        if ($role eq $IPA_ROLE_AII) {
            # AII acts on behalf of a host, but is run by admin on teh AII host.
            # For now, hardcoded. Could be made configurable via config file
            $principal = $IPA_DEFAULT_AII_PRINCIPAL;
            $keytab = $IPA_DEFAULT_AII_KEYTAB;
            $self->verbose("AII role $IPA_ROLE_AII using predefined principal $principal keytab $keytab")
        } elsif ($role_principal) {
            $principal = $role_principal->{principal};
            $keytab = $role_principal->{keytab};
            $self->verbose("IPA client with role $role principal $principal keytab $keytab");
        } elsif ($role eq $IPA_ROLE_CLIENT) {
            $self->verbose("IPA client with role $role and default principal $principal keytab $keytab");
        } else {
            return $self->fail("IPA client with role $role but no principal/keytab specified");
        };
    };

    $self->debug(1, "Creating Kerberos instance");
    $_krb = CAF::Kerberos->new(
        principal => $principal,
        keytab => $keytab,
        log => $self,
        );
    return $self->fail("Failed to get kerberos context: $_krb->{fail}") if(! defined($_krb->get_context(usecred => 1)));

    # set environment to temporary credential cache
    # temporary cache is cleaned-up during destroy of $krb
    local %ENV;
    $_krb->update_env(\%ENV);

    my $dbglvl = $self->{LOGGER} ? $self->{LOGGER}->get_debuglevel() : 0;

    # Only allow kerberos for now
    $self->debug(1, "Creating FreeIPA::Client instance");
    $_client = NCM::Component::FreeIPA::Client->new(
        $tree->{primary},
        log => $self,
        debugapi => $dbglvl >= $DEBUGAPI_LEVEL,
        );

    return $_client;
}

# wrap around _set_ipa_client with error reporting
# sets the $_client variable
# Returns $_client on success, undef otherwise
sub set_ipa_client
{
    my $self = shift;

    $self->_set_ipa_client(@_);

    if ($_client && $_client->{rc}) {
        return $_client;
    } else {
        my $msg = $_client ? $_client->{error} : "client undefined: $self->{fail}";
        $self->error("Failed to obtain FreeIPA Client: $msg");
        return;
    };
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

    return if ! $self->set_ipa_client($tree, role => $role);

    $self->server($tree) if $tree->{server};

    $self->client($tree);

    return SUCCESS;
}

# Generates the commandline (for a yum based system) to initialize a IPA system
sub _manual_initialisation
{
    my ($self, $config, %opts) = @_;

    my $tree = $config->getTree($self->prefix());
    my $network = $config->getTree('/system/network');

    my $yum_packages = join(" ", );

    my $domain = $tree->{domain} || $network->{domainname};

    # Is optional, but we use the template value; not the CLI default
    my $hostcert = $tree->{hostcert} ? 1 : 0;

    my @yum = qw(yum -y install);
    push(@yum, @CLI_YUM_PACKAGES);
    push(@yum, qw(-c /tmp/aii/yum/yum.conf)) if $opts{aii};

    my @cli = qw(PERL5LIB=/usr/lib/perl perl -MNCM::Component::FreeIPA::CLI -w -e install --);
    push(@cli,
         '--realm', $tree->{realm},
         '--primary', $tree->{primary},
         '--domain', $domain,
         '--fqdn', $_fqdn,
         '--hostcert', $hostcert,
         '--otp', ($opts{otp} ? $opts{otp} : 'one_time_password_from_ipa_host-mod_--random'),
        );

    my @cmds;
    push(@cmds, join(" ", @yum), join(" ", @cli));

    return join("\n", @cmds);
}


sub Configure
{

    my ($self, $config) = @_;

    $self->set_fqdn(config => $config);

    if ($self->file_exists($IPA_FILE_INITIALISED)) {

        my $tree = $config->getTree($self->prefix());

        $self->_configure($tree);
    } else {
        my $installcmd = $self->_manual_initialisation($config);
        $self->error("FreeIPA not initialised ($IPA_FILE_INITIALISED is missing). Initialise with\n$installcmd.");
    };

    return 1;
}


# AII post_reboot hook
# TODO: requesting a OTP, to be used withing max window seconds
sub aii_post_reboot
{
    my ($self, $config, $path) = @_;

    $self->set_fqdn(config => $config);
    my $tree = $config->getTree($self->prefix());

    # This is a hook, use AII role
    return if ! $self->set_ipa_client($tree, role => $IPA_ROLE_AII);

    my $hook = $config->getTree($path);

    # Add host (should be ok if already exists)
    $_client->add_host($_fqdn, %{$tree->{host}});

    # Mod host to get OTP (should give an error if not allowed)
    my $otp = $_client->host_passwd($_fqdn);
    if ($otp) {
        my $installcmd = $self->_manual_initialisation($config, aii => 1, otp => $otp);
        my $msg = "# freeipa KS post_reboot\necho 'begin freeipa post_reboot'\n\n$installcmd\n\necho 'end freeipa post_reboot'\n";
        print $msg;
    } else {
        $self->error("freeipa post_reboot: no OTP for $_fqdn");
    }

    return 1;
}

# AII remove hook
sub aii_remove
{
    my ($self, $config, $path) = @_;

    $self->set_fqdn(config => $config);
    my $tree = $config->getTree($self->prefix());

    # This is a hook, use AII role
    return if ! $self->set_ipa_client($tree, role => $IPA_ROLE_AII);

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
