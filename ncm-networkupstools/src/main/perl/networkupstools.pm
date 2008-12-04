# ${license-info}
# ${developer-info}
# ${author-info}

# File: networkupstools.pm
# Implementation of ncm-networkupstools
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 1.0.0 : 22/08/08 15:13
#  ** Generated file : do not edit **
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::networkupstools;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Process qw (run);

use constant UPS_CONFIG_DIR	=> '/etc/ups/';

use constant UPS_DEFINITION_FILE	=> UPS_CONFIG_DIR . 'ups.conf';
use constant UPSD_FILE			=> UPS_CONFIG_DIR . 'upsd.conf';
use constant USERS_FILE			=> UPS_CONFIG_DIR . 'upsd.users';
use constant UPS_SCHED_FILE		=> UPS_CONFIG_DIR . 'upssched.conf';
use constant UPS_MONITORING_FILE	=> UPS_CONFIG_DIR . 'upsmon.conf';

use constant PATH => "/software/components/networkupstools";
use constant IDS => (getpwnam ("nut"))[2,3];

use constant UPSDAEMON_STOP	=> qw (/sbin/service ups stop);
use constant UPSDAEMON_START	=> qw (/sbin/service ups start);
use constant { UPSCMD		=> '/usr/bin/upscmd',
	       UPSUSER		=> '-u',
	       UPSPASS		=> '-p',
	       UPSCMDSET	=> '-s' };

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

# Prints the UPS daemon registered users
sub print_users
{
    my ($self, $tree) = @_;

    open (FH, ">" . USERS_FILE);
    while (my ($user, $settings) = each (%{$tree->{users}})) {
	$self->verbose ("Printing settings for user $user");
	print FH join ("\n\t", "[$user]",
		       "password = $settings->{password}",
		       "allowfrom = $settings->{allowfrom}",
		       "instcmds = " .join (',', @{$settings->{instcmds}}),
		       $settings->{upsmon} ? "upsmon $settings->{upsmon}" : "");
	print FH "\n";
    }

    close (FH);
    chown (0, (IDS)[1], USERS_FILE);
}

# Prints the configuration file for the UPS daemon
sub print_upsd
{
    my ($self, $t) = @_;
    my %rules = (allow => [],
		 reject => []);

    open (FH, ">" . UPSD_FILE);

    while (my ($k, $v) = each (%{$t->{upsd}->{acls}})) {
	my $h = $v->{network};
	if ($v->{accept}) {
	    push (@{$rules{allow}}, $k);
	} else {
	    push (@{$rules{reject}}, $k);
	}
	print FH "ACL $k $h\n";
    }
    print FH "ACCEPT ", join (" ", @{$rules{allow}}), "\n";
    print FH "REJECT ", join (" ", @{$rules{reject}}), "\n";

    close (FH);
    chown (0, (IDS)[1], UPSD_FILE);
}

# Prints all UPS definitions on /etc/ups/ups.conf
sub print_ups_defs
{
    my ($self, $t) = @_;

    open (FH, ">" . UPS_DEFINITION_FILE);
    while (my ($ups, $upscfg) = each (%{$t->{upss}})) {
	$self->verbose ("Writing parameters for UPS $ups");
	print FH join ("\n\t",
		       "[$ups]",
		       "driver\t= $upscfg->{driver}",
		       "port\t= $upscfg->{port}",
		       "desc\t= '$upscfg->{description}'",
		      exists ($upscfg->{cable}) ?
		      "cable\t= $upscfg->{cable}" : "",
		      exists ($upscfg->{sdorder}) ?
		      "sdorder\t= $upscfg->{sdorder}" : "",
		       exists ($upscfg->{shutdown}) ?
		       "shutdown\t= $upscfg->{shutdown}" : "");
	if (exists ($upscfg->{snmp})) {
	    $self->debug (5, "UPS $ups has SNMP settings, printing them");
	    my $snmp = $upscfg->{snmp};
	    print FH join ("\n\t",
			   "\n\tmibs\t= $snmp->{mibs}",
			   exists ($snmp->{community}) ?
			   "community\t= $snmp->{community}" : "",
			   exists ($snmp->{pollfreq}) ?
			   "pollfreq\t= $snmp->{pollfreq}" : "");
	}
	print FH "\n" x 3;
    }
    close (FH);
    chown (0, (IDS)[1], UPS_DEFINITION_FILE);
}

# Prints UPS monitoring directives
sub print_upsmon
{
    my ($self, $t) = @_;
    $t = $t->{upsmon};

    open (FH, ">" . UPS_MONITORING_FILE);
    print FH<<EOF;
RUN_AS_USER	$t->{user}
MINSUPPLIES	$t->{supplies}
SHUTDOWNCMD	$t->{shutdown}
NOTIFYCMD	$t->{notifycommand}
POLLFREQ	$t->{pollfreq}
POLLFREQALERT	$t->{pollalert}
HOSTSYNC	$t->{hostsync}
POWERDOWNFLAG	$t->{powerdownflag}
DEADTIME	$t->{deadtime}
RBWARNTIME	$t->{rbwarn}
NOCOMMWARNTIME	$t->{nocommwarn}
EOF

    foreach my $monitor (@{$t->{monitor}}) {
	$self->debug (5, "Printing monitoring statement for $monitor->{ups}");
	print FH join (" ", "MONITOR", $monitor->{ups},
		    $monitor->{power}, $monitor->{user}, $monitor->{password},
		    $monitor->{type}), "\n";
    }
    while (my ($cond, $txt) = each (%{$t->{notifymsgs}})) {
	print FH join (" ", "NOTIFYMSG", uc($cond), '"$txt"'), "\n";
    }
    while (my ($cond, $acts) = each (%{$t->{notifyflags}})) {
	print FH "NOTIFYFLAG ", uc($cond), " ",
	    join ("+", @$acts), "\n";
    }

    close (FH);
    chown (0, (IDS)[1], UPS_MONITORING_FILE);
}

# Prints the upssched configuration
sub print_upssched
{
    my ($self, $t) = @_;
    $t = $t->{upssched};

    open (FH, ">" . UPS_SCHED_FILE);
    print FH <<EOF;
CMDSCRIPT	$t->{cmdscript}
PIPEFN		$t->{pipe}
LOCKFN		$t->{lock}
EOF

    foreach my $at (@{$t->{handlers}}) {
	print FH join (" ",
		       "AT", uc($at->{condition}), $at->{ups}, $at->{action},
		       exists ($at->{timername}) ? $at->{timername}:"",
		       exists ($at->{actionarguments}) ? $at->{actionarguments}:""), "\n";
    }

    close (FH);
    chown (0, (IDS)[1], UPS_SCHED_FILE);
}

# Sends commands to the UPS to change its internal configuration.
sub set_upss
{
    my ($self, $t) = @_;

    while (my ($ups, $st) = each (%{$t->{upss}})) {
	foreach my $cmd (@{$st->{upsconfig}}) {
	    $self->verbose ("Setting $cmd->{setting} for UPS $ups");
	    if ($cmd->{user} =~ m{^([-\w]+)$}) {
		$cmd->{user} = $1;
	    } else {
		$self->error ("Invalid user $cmd->{user} for sending commands ",
			      " to UPS $ups.");
		next;
	    }
	    # The password is free form, let's hope this doesn't break
	    # anything inside the UPS.
	    $cmd->{pass} =~ m{^(.*)$};
	    $cmd->{pass} = $1;
	    if ($cmd->{setting} =~ m{^(\w+=\w+)$}) {
		$cmd->{setting} = $1;
	    } else {
		$self->error ("Invalid setting $cmd->{setting} to be sent to ",
			      "UPS $ups");
		next;
	    }
	    run (UPSCMD, UPSUSER, $cmd->{user}, UPSPASS, $cmd->{pass},
		 UPSCMDSET, $cmd->{setting}, $ups);
	    $self->error ("Failed to set $cmd->{setting} on UPS $ups") if $?;
	}
    }
}

sub Configure
{
    my ($self, $config) = @_;

    my $mask = umask;
    umask (027);
    my $t = $config->getElement (PATH)->getTree;
    $self->print_users ($t);
    $self->print_ups_defs ($t);
    $self->print_upsmon ($t);
    $self->print_upssched ($t);
    $self->print_upsd ($t);
    $self->set_upss ($t);
    umask ($mask);

    # UPS service has problems when reloading drivers, let's wait for
    # the driver processes to stop and then start again.
    run (UPSDAEMON_STOP);
    sleep (5);
    run (UPSDAEMON_START);
    return !$?;
}
