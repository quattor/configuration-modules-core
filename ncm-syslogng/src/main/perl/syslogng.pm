# ${license-info}
# ${developer-info}
# ${author-info}

# File: syslogng.pm
# Implementation of ncm-syslogng
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 1.0.3 : 09/05/08 15:52
# Read carefully http://www.balabit.com/dl/html/syslog-ng-admin-guide_en.html/bk01-toc.html before using this component.
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::syslogng;

use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;
use LC::Process qw (execute);

use constant PATH	=> '/software/components/syslogng/';
use constant SYSLOGFILE	=> '/etc/syslog-ng/syslog-ng.conf';
use constant SYSLOG_PIDFILE => '/var/run/syslog-ng.pid';
use constant SYSLOG_RELOAD => qw (/sbin/service syslog-ng reload);
use constant SYSLOG_START => qw (/sbin/service syslog-ng start);

use constant TYPES => {
		       files	=> 'file',
		       pipes	=> 'pipe',
		       unixdgram=> 'unix-dgram',
		       unixstream=>'unix-stream',
		       udp	=> 'udp',
		       tcp	=> 'tcp',
		       internal => 'internal'
		      };

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

# Prints syslog-ng global options.
sub print_opts
{

	my ($fh, $cfg) = @_;

	print $fh "options {\n";

	while (my ($k, $v) = each (%$cfg)) {
		print $fh "\t$k($v);\n";
	}
	print $fh "};\n";
}

# Prints source statements
sub print_srcs
{
	my ($fh, $cfg) = @_;

	while (my ($n, $src) = each (%$cfg)) {
		print $fh "source $n {\n\t";
		while (my ($t, $val) = each (%$src)) {
			foreach my $i (@$val) {
				print $fh "\t".TYPES->{$t}." (\n";
				print $fh "\t\t$i->{path}\n" if exists $i->{path};
				while (my ($k, $v) = each (%$i)) {
					print $fh "\t\t$k($v)\n" unless $k eq 'path';
				}
				print $fh "\t);\n";
			}
		}
		print $fh "};\n";
	}
}

# Prints destination definitions.
sub print_dsts
{
	my ($fh, $cfg) = @_;

	while (my ($n, $src) = each (%$cfg)) {
		print $fh "destination $n {\n\t";
		while (my ($t, $val) = each (%$src)) {
			foreach my $i (@$val) {
				print $fh "\t",TYPES->{$t}, " (\n";
				print $fh "\t\t$i->{ip}\n" if exists $i->{ip};
				print $fh "\t\t$i->{path}\n" if exists $i->{path};
				while (my ($k, $v) = each (%$i)) {
					print $fh "\t\t$k($v)\n" unless $k eq 'path' ||
					$k eq 'ip';
				}
				print $fh "\t);\n";
			}
		}
		print $fh "};\n";
	}

}


# Prints filter declarations
sub print_filters
{
	my ($fh, $cfg) = @_;

	while (my ($fn, $ft) = each (%$cfg)) {
		print $fh "filter $fn {\n\t";
		my @conds;
		push (@conds, "\tfacility(".
		      join (",", @{$ft->{facility}}). ")\n")
		    if exists $ft->{facility};
		push (@conds, "\tlevel(".
		      join (",", @{$ft->{level}}). ")\n")
		    if exists $ft->{level};
		push (@conds, "\tprogram($ft->{program})\n")
		    if exists $ft->{program};
		push (@conds, "\thost($ft->{host})\n")
		    if exists $ft->{host};
		push (@conds, "\tprogram($ft->{program})\n")
		    if exists $ft->{program};
		print $fh join ("\n\tor\n", @conds), ";\n};\n";
	}
}

sub print_log_flags
{
	my ($fh, $cfg) = @_;

	return unless exists $cfg->{flags};

	my @flags;
	while (my ($k, $v) = each (%$cfg)) {
		push (@flags, $k) if $v;
	}

	print $fh "flags(", join (",", @flags), ");\n";
}

# Prints a log path
sub print_logpaths
{
	my ($fh, $cfg) = @_;

	foreach my $lg (@$cfg) {
		print $fh "log {\n";
		print_log_flags ($fh, $lg->{flags});
		while (my ($k, $v) = each (%$lg)) {
			next if $k eq 'flags';
			$k =~ m{(.+)s};
			my $kv = $1;
			foreach my $i (@$v) {
				print $fh "\t$kv($i);\n";
			}
		}
		print $fh "};\n";
	}
}

# Reloads syslog-ng daemon, if it is running.
sub syslog_reload
{
	if (-f SYSLOG_PIDFILE) {
		execute ([SYSLOG_RELOAD]);
	} else {
		execute ([SYSLOG_START]);
	}
}

sub Configure
{
	my ($self, $config) = @_;

	my $t = $config->getElement (PATH)->getTree;

	my $fh = FileHandle->new (SYSLOGFILE, "w");

	print_opts ($fh, $t->{options});
	print_srcs ($fh, $t->{sources});
	print_dsts ($fh, $t->{destinations});
	print_filters ($fh, $t->{filters});
	print_logpaths ($fh, $t->{log_rules});
	$fh->close;
	syslog_reload;
	return 1;
}

1;
