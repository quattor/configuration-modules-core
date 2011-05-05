# ${license-info}
# ${developer-info}
# ${author-info}

# File: icinga.pm
# Implementation of ncm-icinga
# Author: Wouter Depypere <wouter.depypere@ugent.be>
# Version: 0.0.2 : 11/03/11 10:22
#  ** Generated file : do not edit **
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::icinga;

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

use constant ICINGA_FILES => { general	=>  '/etc/icinga/icinga.cfg',
                               cgi      =>  '/etc/icinga/cgi.cfg',
			       hosts	=>  '/etc/icinga/objects/hosts.cfg',
			       hosts_generic	=>  '/etc/icinga/objects/hosts_generic.cfg',
			       hostgroups=>'/etc/icinga/objects/hostgroups.cfg',
			       services	=>  '/etc/icinga/objects/services.cfg',
			       serviceextinfo=>'/etc/icinga/objects/serviceextinfo.cfg',
			       servicedependencies=>'/etc/icinga/objects/servicedependencies.cfg',
			       servicegroups=>'/etc/icinga/objects/servicegroups.cfg',
			       contacts	=> '/etc/icinga/objects/contacts.cfg',
			       contactgroups=> '/etc/icinga/objects/contactgroups.cfg',
			       commands	=> '/etc/icinga/objects/commands.cfg',
			       macros	=> '/etc/icinga/resource.cfg',
			       timeperiods=> '/etc/icinga/objects/timeperiods.cfg',
			       hostdependencies=>'/etc/icinga/objects/hostdependencies.cfg',
			       ido2db=>'/etc/icinga/ido2db.cfg'
			     };
use constant BASEPATH => "/software/components/icinga/";
use constant REMAINING_OBJECTS => qw {servicegroups hostgroups contactgroups timeperiods};

use constant ICINGAUSR => (getpwnam ("icinga"))[2];
use constant ICINGAGRP => (getpwnam ("icinga"))[3];

use constant ICINGA_PID_FILE => '/var/icinga/icinga.pid';
use constant ICINGA_START => qw (/etc/init.d/icinga start);
use constant ICINGA_RELOAD => qw (/etc/init.d/icinga reload);

use constant ICINGA_SPOOL	=> '/var/icinga/spool/';
use constant ICINGA_CHECK_RESULT => ICINGA_SPOOL . 'checkresults';

# Prints the main Icinga file, icinga.cfg.
sub print_general
{
    my $cfg = shift;
    unlink (ICINGA_FILES->{general});
    open (FH, ">".ICINGA_FILES->{general});

    my $t = $cfg->getElement (BASEPATH . 'general')->getTree;
    my $el;
    my $ed;

    if ($cfg->elementExists (BASEPATH . 'external_files')) { 
	$el = $cfg->getElement (BASEPATH . 'external_files')->getTree;
    } else {
	$el = [];
    }

    if ($cfg->elementExists (BASEPATH . 'external_dirs')) { 
	$ed = $cfg->getElement (BASEPATH . 'external_dirs')->getTree;
    } else {
	$ed = [];
    }

    print FH "log_file=$t->{log_file}\n";

    while (my ($k, $path) = each (%{ICINGA_FILES()})) {
	next if ($k eq 'general' || $k eq 'cgi' || $k eq 'ido2db' );
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
    foreach my $f (@$ed) {
	print FH "cfg_dir=$f\n";
    }

    my $path;
    if ($t->{check_result_path}) {
	$path = $t->{check_result_path};
    } else {
	$path = ICINGA_CHECK_RESULT;
    }
    mkpath ($path);
    chown (ICINGAUSR, ICINGAGRP, ICINGA_SPOOL) if -d ICINGA_SPOOL;
    chown (ICINGAUSR, ICINGAGRP, $path);
    close (FH);
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{general});
    chmod (0664, ICINGA_FILES->{general});
    chmod (0770, ICINGA_SPOOL, $path);
}

# Prints the IcingaCGI configuration file, cgi.cfg.
sub print_cgi
{
    my $cfg = shift;

    if ( $cfg->elementExists (BASEPATH . 'cgi') ) {
        unlink (ICINGA_FILES->{cgi});
        open (FH, ">".ICINGA_FILES->{cgi});

        my $t = $cfg->getElement (BASEPATH . 'cgi')->getTree;
        print FH "main_config_file=".ICINGA_FILES->{general}."\n";
        print FH "physical_html_path=$t->{physical_html_path}\n";
        print FH "url_html_path=$t->{url_html_path}\n";
        print FH "show_context_help=$t->{show_context_help}\n";
        print FH "use_pending_states=$t->{use_pending_states}\n";
        print FH "use_authentication=$t->{use_authentication}\n";
        print FH "use_ssl_authentication=$t->{use_ssl_authentication}\n";
        print FH "show_all_services_host_is_authorized_for=$t->{show_all_services_host_is_authorized_for}\n";
        print FH "default_statusmap_layout=$t->{default_statusmap_layout}\n";
        print FH "default_statuswrl_layout=$t->{default_statuswrl_layout}\n";
        print FH "ping_syntax=$t->{ping_syntax}\n";
        print FH "refresh_rate=$t->{refresh_rate}\n";
        print FH "escape_html_tags=$t->{escape_html_tags}\n";
        print FH "persistent_ack_comments=$t->{persistent_ack_comments}\n";
        print FH "action_url_target=$t->{action_url_target}\n";
        print FH "notes_url_target=$t->{notes_url_target}\n";
        print FH "lock_author_names=$t->{lock_author_names}\n";
        print FH "status_show_long_plugin_output=$t->{status_show_long_plugin_output}\n";
        print FH "tac_show_only_hard_state=$t->{tac_show_only_hard_state}\n";
        

        # optional fields
        foreach my $opt ( qw { icinga_check_command
                               default_user_name 
                               authorized_for_system_information
                               authorized_for_system_commands
                               authorized_for_configuration_information
                               authorized_for_all_services
                               authorized_for_all_hosts
                               authorized_for_all_service_commands
                               authorized_for_all_host_commands
                               authorized_for_read_only
                               statusmap_background_image
                               statuswrl_include
                               host_unreachable_sound
                               host_down_sound
                               service_critical_sound
                               service_warning_sound
                               service_unknown_sound
                               normal_sound
                               csv_delimiter
                               csv_data_enclosure
                               enable_splunk_integration
                               splunk_url
                             } ) {
            if ( $t->{$opt} ) {
                print FH "$opt=$t->{$opt}\n";   
            }
        }

        chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{cgi});
        chmod (0666, ICINGA_FILES->{cgi});
    }
}

# Prints all the host template definitions on /etc/icinga/objects/hosts_generic.cfg
sub print_hosts_generic
{
    my $cfg = shift;

    unlink (ICINGA_FILES->{hosts_generic});
    open (FH, ">".ICINGA_FILES->{hosts_generic});

    if ($cfg->elementExists(BASEPATH . 'hosts_generic' )) {
    	my $t = $cfg->getElement (BASEPATH . 'hosts_generic')->getTree;
    	while (my ($host, $hostdata) = each (%$t)) {
        	print FH "define host {\n";
        	while (my ($k, $v) = each (%$hostdata)) {
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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{hosts_generic});
}


# Prints all the host definitions on /etc/icinga/objects/hosts.cfg
sub print_hosts
{
    my $cfg = shift;

    unlink (ICINGA_FILES->{hosts});
    open (FH, ">".ICINGA_FILES->{hosts});

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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{hosts});
}

# Prints all the service definitions on /etc/icinga/objects/services.cfg
sub print_services
{
    my $cfg = shift;

    unlink (ICINGA_FILES->{services});
    open (FH, ">".ICINGA_FILES->{services});

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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{services});
}

# Prints all the macros to /etc/icinga/resources.cfg
sub print_macros
{
    my $cfg = shift;

    unlink (ICINGA_FILES->{macros});
    open (FH, ">".ICINGA_FILES->{macros});

    my $t = $cfg->getElement (BASEPATH . 'macros')->getTree;

    while (my ($macro, $val) = each (%$t)) {
	print FH "\$$macro\$=$val\n";
    }
    close (FH);
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{macros});
}

# Prints the command definitions to /etc/icinga/objects/commands.cfg
sub print_commands
{
    my $cfg = shift;

    my $t = $cfg->getElement (BASEPATH . 'commands')->getTree;

    unlink (ICINGA_FILES->{commands});
    open (FH, ">".ICINGA_FILES->{commands});
    while (my ($cmd, $cmdline) = each (%$t)) {
	print FH <<EOF;
define command {
	command_name $cmd
	command_line $cmdline
}
EOF
    }

    close (FH);
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{commands});
}
    
# Prints all contacts to /etc/icinga/objects/contacts.cfg
sub print_contacts
{
    my $cfg = shift;

    unlink (ICINGA_FILES->{contacts});
    open (FH, ">".ICINGA_FILES->{contacts});

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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{contacts});
}

# Prints the service dependencies configuration files.
sub print_servicedependencies
{
    my $cfg = shift;
    return unless $cfg->elementExists (BASEPATH . "servicedependencies");

    unlink (ICINGA_FILES->{servicedependencies});
    my $fh = FileHandle->new (ICINGA_FILES->{servicedependencies}, "w");
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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{servicedependencies});
}

# Prints the extended service configuration files.
sub print_serviceextinfo
{
    my $cfg = shift;
    return unless $cfg->elementExists (BASEPATH . "serviceextinfo");

    unlink (ICINGA_FILES->{serviceextinfo});
    my $fh = FileHandle->new (ICINGA_FILES->{serviceextinfo}, "w");
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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{serviceextinfo});
}

# Prints the host dependency configuration files.
sub print_hostdependencies
{
    my $cfg = shift;
    return unless $cfg->elementExists (BASEPATH . "hostdependencies");

    unlink (ICINGA_FILES->{hostdependencies});
    my $fh = FileHandle->new (ICINGA_FILES->{hostdependencies}, "w");
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
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{hostdependencies});
}

# Prints the ido2db configuration file.
sub print_ido2db_config
{
    my $cfg = shift;

    unlink (ICINGA_FILES->{ido2db});
    open (FH, ">".ICINGA_FILES->{ido2db});

    my $t = $cfg->getElement (BASEPATH . 'ido2db')->getTree;

    while (my ($ido2db_setting, $val) = each (%$t)) {
	print FH "$ido2db_setting=$val\n";
    }
    close (FH);
    chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{ido2db});
}

# Configure method. Writes all the configuration files and starts or
# reloads the Icinga service
sub Configure
{
    my ($self, $config) = @_;
    my $mask = umask;
    umask (0117);

    print_general ($config);
    print_cgi ($config);
    print_macros ($config);
    print_hosts ($config);
    print_hosts_generic ($config);
    print_commands ($config);
    print_services ($config);
    print_servicedependencies ($config);
    print_contacts ($config);
    print_serviceextinfo ($config);
    print_hostdependencies ($config);
    print_ido2db_config ($config);

    # Print the rest of objects
    foreach my $i (REMAINING_OBJECTS) {
	next unless $config->elementExists(BASEPATH . $i);
	my $fh = FileHandle->new (ICINGA_FILES->{$i}, "w");
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
	chown (ICINGAUSR, ICINGAGRP, ICINGA_FILES->{$i});
    }
    if (-f ICINGA_PID_FILE) {
	execute ([ICINGA_RELOAD]);
    }
    else {
	execute ([ICINGA_START]);
    }
    umask ($mask);
    return !$?;
}
