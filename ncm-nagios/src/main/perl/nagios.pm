#${PMpre} NCM::Component::nagios${PMpost}

use CAF::FileWriter;
use CAF::Service;
use EDG::WP4::CCM::Path qw (unescape);
use Socket;

use File::Path;

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
# TODO: There is still some mkpath/... to be replaced by CAF::Path
#our $NoActionSupported = 1;

use constant NAGIOS_FILES => {
    general	=> '/etc/nagios/nagios.cfg',
    cgi => '/etc/nagios/cgi.cfg',
    hosts => '/etc/nagios/hosts.cfg',
    hosts_generic => '/etc/nagios/hosts_generic.cfg',
    hostgroups => '/etc/nagios/hostgroups.cfg',
    services => '/etc/nagios/services.cfg',
    serviceextinfo => '/etc/nagios/serviceextinfo.cfg',
    servicedependencies => '/etc/nagios/servicedependencies.cfg',
    servicegroups => '/etc/nagios/servicegroups.cfg',
    contacts => '/etc/nagios/contacts.cfg',
    contactgroups => '/etc/nagios/contactgroups.cfg',
    commands => '/etc/nagios/commands.cfg',
    macros => '/etc/nagios/resources.cfg',
    timeperiods => '/etc/nagios/timeperiods.cfg',
    hostdependencies => '/etc/nagios/hostdependencies.cfg',
};

use constant REMAINING_OBJECTS => qw {servicegroups hostgroups contactgroups timeperiods};

use constant NAGIOSUSR => (getpwnam ("nagios"))[2];
use constant NAGIOSGRP => (getpwnam ("nagios"))[3];

use constant NAGIOS_PID_FILE => '/var/run/nagios.pid';

use constant NAGIOS_SPOOL	=> '/var/log/nagios/spool/';
use constant NAGIOS_CHECK_RESULT => NAGIOS_SPOOL . 'checkresults';

# Make CAF::FileWriter instance with 0660 perms and NAGIOSUSR:NAGIOSGRP
sub _mk_fh
{
    my ($self, $name) = @_;
    return CAF::FileWriter->new(NAGIOS_FILES->{$name},
                                mode => 0660,
                                owner => NAGIOSUSR,
                                group => NAGIOSGRP,
                                log => $self);
}

# Prints the main Nagios file, nagios.cfg.
sub print_general
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("general");

    my $t = $cfg->getElement ($self->prefix() . '/general')->getTree;
    my ($el, $ed);

    if ($cfg->elementExists ($self->prefix() . '/external_files')) {
        $el = $cfg->getElement ($self->prefix() . '/external_files')->getTree;
    } else {
        $el = [];
    }

    if ($cfg->elementExists ($self->prefix() . '/external_dirs')) {
        $ed = $cfg->getElement ($self->prefix() . '/external_dirs')->getTree;
    } else {
        $ed = [];
    }

    print $fh "log_file=$t->{log_file}\n";

    while (my ($k, $path) = each (%{NAGIOS_FILES()})) {
        next if ($k eq 'general' || $k eq 'cgi');
        if ($cfg->elementExists ($self->prefix()."/$k")) {
            print $fh $k eq 'macros' ? "resource_file" : "cfg_file", "=$path\n";
        }
    }
    while (my ($k, $v) = each (%$t)) {
        next if $k eq 'log_file';
        if (ref ($v)) {
            print $fh "$k=", join ("!", @$v), "\n";
        } else {
            print $fh "$k=$v\n";
        }
    }

    foreach my $f (@$el) {
        print $fh "cfg_file=$f\n";
    }
    foreach my $f (@$ed) {
        print $fh "cfg_dir=$f\n";
    }

    my $path;
    if ($t->{check_result_path}) {
        $path = $t->{check_result_path};
    } else {
        $path = NAGIOS_CHECK_RESULT;
    }

    mkpath ($path);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_SPOOL) if -d NAGIOS_SPOOL;
    chown (NAGIOSUSR, NAGIOSGRP, $path);
    chmod (0770, NAGIOS_SPOOL, $path);

    $fh->close();
}

# Prints the NagiosCGI configuration file, cgi.cfg.
sub print_cgi
{
    my ($self, $cfg) = @_;

    if ( $cfg->elementExists ($self->prefix() . '/cgi') ) {
        my $fh = $self->_mk_fh("cgi");

        my $t = $cfg->getElement ($self->prefix() . '/cgi')->getTree;
        print $fh "main_config_file=".NAGIOS_FILES->{general}."\n";

        print $fh "physical_html_path=$t->{physical_html_path}\n";
        print $fh "url_html_path=$t->{url_html_path}\n";
        print $fh "show_context_help=$t->{show_context_help}\n";
        print $fh "use_authentication=$t->{use_authentication}\n";
        print $fh "default_statusmap_layout=$t->{default_statusmap_layout}\n";
        print $fh "default_statuswrl_layout=$t->{default_statuswrl_layout}\n";
        print $fh "ping_syntax=$t->{ping_syntax}\n";
        print $fh "refresh_rate=$t->{refresh_rate}\n";

        # optional fields
        foreach my $opt ( qw { nagios_check_command
                               default_user_name
                               authorized_for_system_information
                               authorized_for_system_commands
                               authorized_for_configuration_information
                               authorized_for_all_services
                               authorized_for_all_hosts
                               authorized_for_all_service_commands
                               authorized_for_all_host_commands
                               statusmap_background_image
                               statuswrl_include
                               host_unreachable_sound
                               host_down_sound
                               service_critical_sound
                               service_warning_sound
                               service_unknown_sound
                               normal_sound
                             } ) {
            if ( $t->{$opt} ) {
                print $fh "$opt=$t->{$opt}\n";
            }
        }

        $fh->close();
    }
}

# Prints all the host template definitions on /etc/nagios/hosts_generic.cfg
sub print_hosts_generic
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("hosts_generic");

    if ($cfg->elementExists($self->prefix() . '/hosts_generic' )) {
    	my $t = $cfg->getElement ($self->prefix() . '/hosts_generic')->getTree;
    	while (my ($host, $hostdata) = each (%$t)) {
        	print $fh "define host {\n";
        	while (my ($k, $v) = each (%$hostdata)) {
                if (ref ($v)) {
                    if ($k =~ m{command} || $k =~ m{handler}) {
                        print $fh "\t$k\t", join ("!", @$v), "\n";
                    } else {
                        print $fh "\t$k\t", join (",", @$v), "\n";
                    }
                } else {
                    print $fh "\t$k\t$v\n";
           		}
        	}
        	print $fh "}\n";
    	}
    }

    $fh->close();
}


# Prints all the host definitions on /etc/nagios/hosts.cfg
sub print_hosts
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("hosts");

    my $t = $cfg->getElement ($self->prefix() . '/hosts')->getTree;
    while (my ($host, $hostdata) = each (%$t)) {
        print $fh "define host {\n\thost_name\t$host\n";
        while (my ($k, $v) = each (%$hostdata)) {
            if (ref ($v)) {
                if ($k =~ m{command} || $k =~ m{handler}) {
                    print $fh "\t$k\t", join ("!", @$v), "\n";
                } else {
                    print $fh "\t$k\t", join (",", @$v), "\n";
                }
            } else {
                print $fh "\t$k\t$v\n";
            }
        }
        unless (exists $hostdata->{address}) {
            $self->debug (5, "DNS looking for $host");
            my @addr = gethostbyname ($host);
            print $fh "\taddress\t", inet_ntoa ($addr[4]), "\n";
        }
        print $fh "}\n";
    }

    $fh->close();
}

# Prints all the host definitions on /etc/nagios/hosts.cfg
sub print_services
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("services");

    my $t = $cfg->getElement ($self->prefix() . '/services')->getTree;
    while (my ($service, $serviceinstances) = each (%$t)) {
        foreach my $servicedata (@$serviceinstances) {
            print $fh "define service {\n\tservice_description\t", unescape ($service), "\n";
            while (my ($k, $v) = each (%$servicedata)) {
                if (ref ($v)) {
                    if ($k =~ m{command} || $k =~ m{handler}) {
                        print $fh "\t$k\t", join ("!", @$v), "\n";
                    } else {
                        print $fh "\t$k\t", join (",", @$v), "\n";
                    }
                } else {
                    print $fh "\t$k\t$v\n";
                }
            }
            print $fh "}\n";
        }
    }
    $fh->close();
}

# Prints all the macros to /etc/nagios/resources.cfg
sub print_macros
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("macros");

    my $t = $cfg->getElement ($self->prefix() . '/macros')->getTree;

    while (my ($macro, $val) = each (%$t)) {
        print $fh "\$$macro\$=$val\n";
    }

    $fh->close();
}

# Prints the command definitions to /etc/nagios/commands.cfg
sub print_commands
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("commands");

    my $t = $cfg->getElement ($self->prefix() . '/commands')->getTree;

    while (my ($cmd, $cmdline) = each (%$t)) {
        print $fh <<"EOF";
define command {
	command_name $cmd
	command_line $cmdline
}
EOF
    }

    $fh->close();
}

# Prints all contacts to /etc/nagios/contacts.cfg
sub print_contacts
{
    my ($self, $cfg) = @_;

    my $fh = $self->_mk_fh("contacts");

    my $t = $cfg->getElement ($self->prefix() . '/contacts')->getTree;
    while (my ($cnt, $cntst) = each (%$t)) {
        print $fh "define contact {\n\tcontact_name\t$cnt\n";
        while (my ($k, $v) = each (%$cntst)) {
            print $fh "\t$k\t";
            if (ref ($v)) {
                my @s;
                if ($k =~ m{commands}) {
                    push (@s, join ('!', @$_)) foreach @$v;
                } else {
                    @s = @$v;
                }
                print $fh join (',', @s);
            } else {
                print $fh $v;
            }
            print $fh "\n";
        }
        print $fh "}\n";
    }

    $fh->close();
}

# Prints the service dependencies configuration files.
sub print_servicedependencies
{
    my ($self, $cfg) = @_;

    return unless $cfg->elementExists ($self->prefix() . "/servicedependencies");

    my $fh = $self->_mk_fh("servicedependencies");

    my $t = $cfg->getElement ($self->prefix() . "/servicedependencies")->getTree;

    foreach my $i (@$t) {
        print $fh "define servicedependency {\n";
        while (my ($k, $v) = each (%$i)) {
            print $fh "\t$k\t", ref ($v)? join (',', @$v): $v;
            print $fh "\n";
        }
        print $fh "}\n";
    }
    $fh->close();
}

# Prints the extended service configuration files.
sub print_serviceextinfo
{
    my ($self, $cfg) = @_;

    return unless $cfg->elementExists ($self->prefix() . "/serviceextinfo");

    my $fh = $self->_mk_fh("serviceextinfo");

    my $t = $cfg->getElement ($self->prefix() . "/serviceextinfo")->getTree;

    foreach my $i (@$t) {
        print $fh "define serviceextinfo {\n";
        while (my ($k, $v) = each (%$i)) {
            print $fh "\t$k\t", ref ($v)? join (',', @$v): $v;
            print $fh "\n";
        }
        print $fh "}\n";
    }
    $fh->close();
}

# Prints the host dependency configuration files.
sub print_hostdependencies
{
    my ($self, $cfg) = @_;

    return unless $cfg->elementExists ($self->prefix() . "/hostdependencies");

    my $fh = $self->_mk_fh("hostdependencies");

    my $t = $cfg->getElement ($self->prefix() . "/hostdependencies")->getTree;

    while (my ($host, $dependency) = each (%$t)) {
        print $fh "define hostdependency {\n\thost_name\t$host\n";
        while (my ($k, $v) = each (%$dependency)) {
            print $fh "\t$k\t", ref ($v) ? join (',', @$v):$v, "\n";
        }
        print $fh "}\n";
    }
    $fh->close();
}

# Configure method. Writes all the configuration files and starts or
# reloads the Nagios service
sub Configure
{
    my ($self, $config) = @_;

    $self->print_general ($config);
    $self->print_cgi ($config);
    $self->print_macros ($config);
    $self->print_hosts ($config);
    $self->print_hosts_generic ($config);
    $self->print_commands ($config);
    $self->print_services ($config);
    $self->print_servicedependencies ($config);
    $self->print_contacts ($config);
    $self->print_serviceextinfo ($config);
    $self->print_hostdependencies ($config);

    # Print the rest of objects
    foreach my $i (REMAINING_OBJECTS) {
        next unless $config->elementExists($self->prefix() . "/$i");
        my $fh = $self->_mk_fh($i);

        my $t = $config->getElement ($self->prefix() . "/$i")->getTree;
        $i =~ m{(.*[^s])s?$};
        my $kv = $1;
        while (my ($k, $v) = each (%$t)) {
            print $fh "define $kv {\n\t$kv","_name\t$k\n";
            while (my ($a, $b) = each (%$v)) {
                if (ref ($b)) {
                    print $fh "\t$a\t", join (",", @$b), "\n";
                } else {
                    print $fh "\t$a\t$b\n";
                }
            }
            print $fh "}\n";
        }
        $fh->close();
    }

    my $srv = CAF::Service->new(['nagios'], log => $self);
    if (-f NAGIOS_PID_FILE) {
        $srv->reload();
    } else {
        $srv->start();
    }
}

1;
