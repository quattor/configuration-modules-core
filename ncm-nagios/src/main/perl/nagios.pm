# ${license-info}
# ${developer-info}
# ${author-info}

# File: nagios.pm
# Implementation of ncm-nagios
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 1.4.8 : 23/01/09 14:14
#  ** Generated file : do not edit **
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::nagios;

use strict;
use warnings;
use NCM::Component ;
use EDG::WP4::CCM::Property;
use EDG::WP4::CCM::Element qw (unescape);
use Socket;
use LC::Process qw (execute);
use LC::Exception qw (throw_error);
use File::Path;

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
our $this_app = $NCM::Component::this_app;

use constant NAGIOS_FILES => { general	=>  '/etc/nagios/nagios.cfg',
                               cgi      =>  '/etc/nagios/cgi.cfg',
			       hosts	=>  '/etc/nagios/hosts.cfg',
			       hostgroups=>'/etc/nagios/hostgroups.cfg',
			       services	=>  '/etc/nagios/services.cfg',
			       serviceextinfo=>'/etc/nagios/serviceextinfo.cfg',
			       servicedependencies=>'/etc/nagios/servicedependencies.cfg',
			       servicegroups=>'/etc/nagios/servicegroups.cfg',
			       contacts	=> '/etc/nagios/contacts.cfg',
			       contactgroups=> '/etc/nagios/contactgroups.cfg',
			       commands	=> '/etc/nagios/commands.cfg',
			       macros	=> '/etc/nagios/resources.cfg',
			       timeperiods=> '/etc/nagios/timeperiods.cfg',
			       hostdependencies=>'/etc/nagios/hostdependencies.cfg',
			     };
use constant BASEPATH => "/software/components/nagios/";
use constant REMAINING_OBJECTS => qw {servicegroups hostgroups contactgroups timeperiods};

use constant NAGIOSUSR => (getpwnam ("nagios"))[2];
use constant NAGIOSGRP => (getpwnam ("nagios"))[3];

use constant NAGIOS_PID_FILE => '/var/run/nagios.pid';
use constant NAGIOS_START => qw (/etc/init.d/nagios start);
use constant NAGIOS_RELOAD => qw (/etc/init.d/nagios reload);

use constant NAGIOS_SPOOL	=> '/var/log/nagios/spool/';
use constant NAGIOS_CHECK_RESULT => NAGIOS_SPOOL . 'checkresults';

# Prints the main Nagios file, nagios.cfg.
sub print_general
{
    my $cfg = shift;
    unlink (NAGIOS_FILES->{general});
    open (FH, ">".NAGIOS_FILES->{general});

    my $t = $cfg->getElement (BASEPATH . 'general')->getTree;
    my $el;

    if ($cfg->elementExists (BASEPATH . 'external_files')) { 
	$el = $cfg->getElement (BASEPATH . 'external_files')->getTree;
    } else {
	$el = [];
    }

    print FH "log_file=$t->{log_file}\n";

    while (my ($k, $path) = each (%{NAGIOS_FILES()})) {
	next if ($k eq 'general' || $k eq 'cgi');
	if ($cfg->elementExists (BASEPATH.$k)) {
	    print FH $k eq 'macros'?"resource_file":"cfg_file",
		 "=$path\n";
	}
    }
    while (my ($k, $v) = each (%$t)) {
	next if $k eq 'log_file';
	if (ref ($v)) {
	    print FH "$k=", join ("!", @$v), "\n";
	}
	else {
	    print FH "$k=$v\n";
	}
    }
    foreach my $f (@$el) {
	print FH "cfg_file=$f\n";
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
    close (FH);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{general});
    chmod (0770, NAGIOS_SPOOL, $path);
}

# Prints the NagiosCGI configuration file, cgi.cfg.
sub print_cgi
{
    my $cfg = shift;

    if ( $cfg->elementExists (BASEPATH . 'cgi') ) {
        unlink (NAGIOS_FILES->{cgi});
        open (FH, ">".NAGIOS_FILES->{cgi});

        my $t = $cfg->getElement (BASEPATH . 'cgi')->getTree;
        print FH "main_config_file=".NAGIOS_FILES->{general}."\n";

        print FH "physical_html_path=$t->{physical_html_path}\n";
        print FH "url_html_path=$t->{url_html_path}\n";
        print FH "show_context_help=$t->{show_context_help}\n";
        print FH "use_authentication=$t->{use_authentication}\n";
        print FH "default_statusmap_layout=$t->{default_statusmap_layout}\n";
        print FH "default_statuswrl_layout=$t->{default_statuswrl_layout}\n";
        print FH "ping_syntax=$t->{ping_syntax}\n";
        print FH "refresh_rate=$t->{refresh_rate}\n";

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
                print FH "$opt=$t->{$opt}\n";   
            }
        }

        chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{cgi});
        chmod (0660, NAGIOS_FILES->{cgi});
    }
}

# Prints all the host definitions on /etc/nagios/hosts.cfg
sub print_hosts
{
    my $cfg = shift;

    unlink (NAGIOS_FILES->{hosts});
    open (FH, ">".NAGIOS_FILES->{hosts});

    my $t = $cfg->getElement (BASEPATH . 'hosts')->getTree;
    while (my ($host, $hostdata) = each (%$t)) {
	print FH "define host {\n",
	     "\thost_name\t$host\n";
	while (my ($k, $v) = each (%$hostdata)) {
	    if (ref ($v)) {
		if ($k =~ m{command} || $k =~ m{handler}) {
		    print FH "\t$k\t", join ("!", @$v), "\n";
		}
		else {
		    print FH "\t$k\t", join (",", @$v), "\n";
		}
	    }
	    else {
		print FH "\t$k\t$v\n";
	    }
	}
	unless (exists $hostdata->{address}) {
	    $this_app->debug (5, "DNS looking for $host");
	    my @addr = gethostbyname ($host);
	    print FH "\taddress\t", inet_ntoa ($addr[4]), "\n";
	}
	print FH "}\n";
    }
    close (FH);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{hosts});
}

# Prints all the host definitions on /etc/nagios/hosts.cfg
sub print_services
{
    my $cfg = shift;

    unlink (NAGIOS_FILES->{services});
    open (FH, ">".NAGIOS_FILES->{services});

    my $t = $cfg->getElement (BASEPATH . 'services')->getTree;
    while (my ($service, $serviceinstances) = each (%$t)) {
	foreach my $servicedata (@$serviceinstances) {
	    print FH "define service {\n",
		"\tservice_description\t", unescape ($service), "\n";
	    while (my ($k, $v) = each (%$servicedata)) {
		if (ref ($v)) {
		    if ($k =~ m{command} || $k =~ m{handler}) {
			print FH "\t$k\t", join ("!", @$v), "\n";
		    } else {
			print FH "\t$k\t", join (",", @$v), "\n";
		    }
		} else {
		    print FH "\t$k\t$v\n";
		}
	    }
	    print FH "}\n";
	}
    }
    close (FH);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{services});
}

# Prints all the macros to /etc/nagios/resources.cfg
sub print_macros
{
    my $cfg = shift;

    unlink (NAGIOS_FILES->{macros});
    open (FH, ">".NAGIOS_FILES->{macros});

    my $t = $cfg->getElement (BASEPATH . 'macros')->getTree;

    while (my ($macro, $val) = each (%$t)) {
	print FH "\$$macro\$=$val\n";
    }
    close (FH);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{macros});
}

# Prints the command definitions to /etc/nagios/commands.cfg
sub print_commands
{
    my $cfg = shift;

    my $t = $cfg->getElement (BASEPATH . 'commands')->getTree;

    unlink (NAGIOS_FILES->{commands});
    open (FH, ">".NAGIOS_FILES->{commands});
    while (my ($cmd, $cmdline) = each (%$t)) {
	print FH <<EOF;
define command {
	command_name $cmd
	command_line $cmdline
}
EOF
    }

    close (FH);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{commands});
}
    
# Prints all contacts to /etc/nagios/contacts.cfg
sub print_contacts
{
    my $cfg = shift;

    unlink (NAGIOS_FILES->{contacts});
    open (FH, ">".NAGIOS_FILES->{contacts});

    my $t = $cfg->getElement (BASEPATH . 'contacts')->getTree;
    while (my ($cnt, $cntst) = each (%$t)) {
	print FH "define contact {\n",
	     "\tcontact_name\t$cnt\n";
	while (my ($k, $v) = each (%$cntst)) {
	    print FH "\t$k\t";
	    if (ref ($v)) {
		my @s;
		if ($k =~ m{commands}) {
		    push (@s, join ('!', @$_)) foreach @$v;
		}
		else {
		    @s = @$v;
		}
		print FH join (',', @s);
	    }
	    else {
		print FH $v;
	    }
	    print FH "\n";
	}
	print FH "}\n";
    }
    close (FH);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{contacts});
}

# Prints the service dependencies configuration files.
sub print_servicedependencies
{
    my $cfg = shift;
    return unless $cfg->elementExists (BASEPATH . "servicedependencies");

    unlink (NAGIOS_FILES->{servicedependencies});
    my $fh = FileHandle->new (NAGIOS_FILES->{servicedependencies}, "w");
    my $t = $cfg->getElement (BASEPATH . "servicedependencies")->getTree;

    foreach my $i (@$t) {
        print $fh "define servicedependency {\n";
        while (my ($k, $v) = each (%$i)) {
            print $fh "\t$k\t", ref ($v)? join (',', @$v): $v;
            print $fh "\n";
        }
        print $fh "}\n";
    }
    close ($fh);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{servicedependencies});
}

# Prints the extended service configuration files.
sub print_serviceextinfo
{
    my $cfg = shift;
    return unless $cfg->elementExists (BASEPATH . "serviceextinfo");

    unlink (NAGIOS_FILES->{serviceextinfo});
    my $fh = FileHandle->new (NAGIOS_FILES->{serviceextinfo}, "w");
    my $t = $cfg->getElement (BASEPATH . "serviceextinfo")->getTree;

    foreach my $i (@$t) {
	print $fh "define serviceextinfo {\n";
	while (my ($k, $v) = each (%$i)) {
	    print $fh "\t$k\t", ref ($v)? join (',', @$v): $v;
	    print $fh "\n";
	}
	print $fh "}\n";
    }
    close ($fh);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{serviceextinfo});
}

# Prints the host dependency configuration files.
sub print_hostdependencies
{
    my $cfg = shift;
    return unless $cfg->elementExists (BASEPATH . "hostdependencies");

    unlink (NAGIOS_FILES->{hostdependencies});
    my $fh = FileHandle->new (NAGIOS_FILES->{hostdependencies}, "w");
    my $t = $cfg->getElement (BASEPATH . "hostdependencies")->getTree;

    while (my ($host, $dependency) = each (%$t)) {
	print $fh "define hostdependency {\n",
	    "\thost_name\t$host\n";
	while (my ($k, $v) = each (%$dependency)) {
	    print $fh "\t$k\t", ref ($v) ? join (',', @$v):$v, "\n";
	}
	print $fh "}\n";
    }
    close ($fh);
    chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{hostdependencies});
}

# Configure method. Writes all the configuration files and starts or
# reloads the Nagios service
sub Configure
{
    my ($self, $config) = @_;
    my $mask = umask;
    umask (0117);

    print_general ($config);
    print_cgi ($config);
    print_macros ($config);
    print_hosts ($config);
    print_commands ($config);
    print_services ($config);
    print_servicedependencies ($config);
    print_contacts ($config);
    print_serviceextinfo ($config);
    print_hostdependencies ($config);

    # Print the rest of objects
    foreach my $i (REMAINING_OBJECTS) {
	next unless $config->elementExists(BASEPATH . $i);
	my $fh = FileHandle->new (NAGIOS_FILES->{$i}, "w");
	my $t = $config->getElement (BASEPATH.$i)->getTree;
	$i =~ m{(.*[^s])s?$};
	my $kv = $1;
	while (my ($k, $v) = each (%$t)) {
	    print $fh "define $kv {\n",
		 "\t$kv","_name\t$k\n";
	    while (my ($a, $b) = each (%$v)) {
		if (ref ($b)) {
		    print $fh "\t$a\t", join (",", @$b), "\n";
		}
		else {
		    print $fh "\t$a\t$b\n";
		}
	    }
	    print $fh "}\n";
	}
	close ($fh);
	chown (NAGIOSUSR, NAGIOSGRP, NAGIOS_FILES->{$i});
    }
    if (-f NAGIOS_PID_FILE) {
	execute ([NAGIOS_RELOAD]);
    }
    else {
	execute ([NAGIOS_START]);
    }
    umask ($mask);
    return !$?;
}
