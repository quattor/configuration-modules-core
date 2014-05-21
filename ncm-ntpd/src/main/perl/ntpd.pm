# ${license-info}
# ${developer-info}
# ${author-info}

#
# ${project.artifactId} - NCM ${project.artifactId} configuration component
#
# Configure the ntp time daemon
#
################################################################################

package NCM::Component::${project.artifactId};

#
# a few standard statements, mandatory for all components
#

use strict;
use warnings;

use base qw(NCM::Component);

use LC::Exception;

use NCM::Component;
use Socket;
use Sys::Hostname;
use EDG::WP4::CCM::Element;
use CAF::FileWriter;
use CAF::Process;
use Data::Dumper;
use Readonly;

Readonly::Scalar my $PATH     => '/software/components/${project.artifactId}';
Readonly::Scalar my $COMPNAME => 'ncm-${project.artifactId}';

Readonly::Scalar my $DEFAULT_SERVICE    => '${project.artifactId}';
Readonly::Scalar my $DEFAULTSOL_SERVICE => 'svc:/network/ntp';

Readonly::Scalar our $NTPDCONF    => '/etc/ntp.conf';
Readonly::Scalar our $STEPTICKERS => '/etc/ntp/step-tickers';

our $EC = LC::Exception::Context->new->will_store_all;
$NCM::Component::ntpd::NoActionSupported = 1;

sub Configure {
	my ($self, $config) = @_;

	# Getting the time servers from "/software/components/ntpd/servers"
	# with IP address
	#
	my @ntp_servers;
	my @client_networks;

	if ($NoAction) {
		$self->warn("Running Configure with NoAction set to $NoAction");
	}

	my $cfg = $config->getElement($PATH)->getTree();

	# look for legacy-style servers
	if (exists $cfg->{servers} and ref($cfg->{servers}) eq 'ARRAY') {
		foreach my $time_server (@{$cfg->{servers}}) {
			my $ip = gethostbyname($time_server);
			if (!defined $ip) {
				$self->warn("Unknown/unresolvable NTP server $time_server - ignoring!");
				next;
			}
			$ip = inet_ntoa($ip);
			push(@ntp_servers, {
					server_address => $ip,
					server_options => $cfg->{defaultoptions},
				}
			);
			$self->debug(3, "found NTP server $ip (for $time_server)");
		}
	}

	# look for serverlist (with options)
	if (exists $cfg->{serverlist} and ref($cfg->{serverlist}) eq 'ARRAY') {

		# check if we have a list of nlists (with options)
		foreach my $time_server_def (@{$cfg->{serverlist}}) {
			my $time_server = $time_server_def->{server};
			my $ip          = gethostbyname($time_server);
			if (!defined $ip) {
				$self->warn("Unknown/unresolvable NTP server $time_server - ignoring!");
				next;
			}
			$ip = inet_ntoa($ip);
			push(@ntp_servers, {
					server_address => $ip,
					server_options => $time_server_def->{options} || $cfg->{defaultoptions},
				}
			);
			$self->debug(3, "found NTP server $ip (for $time_server)");
		}
	}

	unless (scalar @ntp_servers > 0) {
		$self->error("No (valid) ntp server(s) defined");
		return 0;
	}

	if (exists $cfg->{clientnetworks} && ref($cfg->{clientnetworks} eq 'ARRAY')) {
		foreach my $client (@{$cfg->{clientnetworks}}) {
			if (exists $client->{net} && exists $client->{mask}) {
				push(@client_networks, [$client->{net}, $client->{mask}]);
				$self->debug(3, "found NTP client net $client->{net}/$client->{mask}");
			}
		}
	}

	# Declare the ntp servers in /etc/ntp.conf and /etc/ntp/step-tickers
	my $ntpconf_changed = $self->write_ntpd_config($cfg, \@ntp_servers, \@client_networks);
	my $ntpstep_changed = $self->write_ntpd_step_tickers($cfg, \@ntp_servers);

	# Restart the daemon if necessary.
	if ( $self->needs_restarting($ntpconf_changed, $ntpstep_changed) ) {
		$self->restart_service_ntpd($cfg);
	} else {
		$self->debug(1,'no config file changes, no restart of ${project.artifactId} required');
	}

	return 1;
}

sub write_ntpd_step_tickers {
	my ($self, $cfg, $ntp_servers) = @_;

	my $stfh = CAF::FileWriter->new(
		$STEPTICKERS,
		log    => $self,
		mode   => 0644,
		backup => '.old',
	);

	if (@{$ntp_servers}) {
		print $stfh map { $_->{server_address} . "\n" } @{$ntp_servers};
	}

	return $stfh->close();
}


sub write_ntpd_config {
	my ($self, $cfg, $ntp_servers, $client_networks) = @_;

	my $fh = CAF::FileWriter->new(
		$NTPDCONF,
		log    => $self,
		mode   => 0644,
		backup => '.old',
	);

	print $fh "# This file is under $COMPNAME control.\n";

	if ($cfg->{restrictdefault}) {
		my $opts = $cfg->{restrictdefault};
		my @o    = map {
			if    ($_ =~ m/mask/i) { "$_ $opts->{$_}"; }
			elsif ($opts->{$_})    { "$_"; }
		} sort keys %$opts;
		my $optstring = join(" ", @o);
		print $fh "restrict default $optstring\n";
	} else {
		# proper access control - restrictive by default
		print $fh "restrict default ignore\n";
	}

	if ($cfg->{authenticate}) {
		print $fh "\nauthenticate yes\n";
	}

	if ($cfg->{broadcastdelay}) {
		print $fh "\nbroadcastdelay $cfg->{broadcastdelay}\n";
	}

	# keys....
	if ($cfg->{keyfile}) {
		print $fh "\n# access keys\n";
		print $fh "keys  $cfg->{keyfile}\n";
		if ($cfg->{trustedkey}) {
			print $fh "trustedkey    " . join(" ", sort { $a <=> $b } @{$cfg->{trustedkey}}) . "\n";
		}
		if ($cfg->{requestkey}) {
			print $fh "requestkey    $cfg->{requestkey}\n";
		}
		if ($cfg->{controlkey}) {
			print $fh "controlkey    $cfg->{controlkey}\n";
		}
	}

	# driftfile
	if ($cfg->{driftfile}) {
		print $fh "\ndriftfile $cfg->{driftfile}\n";
	}

	# includefile
	if ($cfg->{includefile}) {
		if (!-e $cfg->{includefile}) {
			$self->warn("include file $cfg->{includefile} does not exist, not including in ntp.conf");
		}
		else {
			print $fh "\nincludefile $cfg->{includefile}\n";
		}
	}

	# tinker
	if (exists $cfg->{tinker} && ref($cfg->{tinker}) eq 'HASH') {
		my $opts      = $cfg->{tinker};
		my @o         = map { "$_ $opts->{$_}"; } sort keys %$opts;
		my $optstring = join(" ", @o);
		print $fh "tinker $optstring\n";
	}

	# enable system options
	if (exists $cfg->{enable} && ref($cfg->{enable}) eq 'HASH') {
		my $opts = $cfg->{enable};
		my @o    = map {
			if ($opts->{$_}) { "$_"; }
		} sort keys %$opts;
		my $optstring = join(" ", @o);
		print $fh "enable $optstring\n";
	}

	# disable system options
	if (exists $cfg->{disable} && ref($cfg->{disable}) eq 'HASH') {
		my $opts = $cfg->{disable};
		my @o    = map {
			if ($opts->{$_}) { "$_"; }
		} sort keys %$opts;
		my $optstring = join(" ", @o);
		print $fh "disable $optstring\n";
	}

	print $fh "\n# Servers\n";

	# configured servers
	for my $ntp_server (@{$ntp_servers}) {
		my $ip = $ntp_server->{server_address};
		my $opts = $ntp_server->{server_options};
		my @o    = ();
		if (ref($opts) eq 'HASH') {
			@o = map {
				if ($_ =~ m/maxpoll|minpoll|key|version/i) {
					"$_ $opts->{$_}";
				}
				elsif ($opts->{$_}) { "$_"; }
			} sort keys %$opts;
		}
		my $optstring = join(" ", @o);
		print $fh "server   $ip $optstring\n";
		print $fh "restrict $ip mask 255.255.255.255 nomodify notrap noquery\n";
	}

	# default is to include
	$cfg->{includelocalhost} = 1 unless (exists  $cfg->{includelocalhost});

	if (exists $cfg->{includelocalhost}) {
		print $fh "\n# add localhost in case of network outages\n";
		print $fh "fudge    127.127.1.0 stratum 10\n";
	}

	# default is to enable
	$cfg->{enablelocalhostdebug} = 1 unless (exists  $cfg->{enablelocalhostdebug});

	if ($cfg->{enablelocalhostdebug}) {
		print $fh "\n# Allow some debugging via ntpdc, but no modifications\n";
		print $fh "restrict 127.0.0.1 nomodify notrap\n";
	}

	# add our own clients in case we are a real "server"
	if (@{$client_networks}) {
		print $fh "server 127.0.0.1\n";
	}
	for my $client (@{$client_networks}) {
		print $fh "restrict " . $$client[0] . " mask " . $$client[1] . " nomodify notrap\n";
	}

	# logfile
	if ($cfg->{logfile}) {
		print $fh "\nlogfile $cfg->{logfile}\n";
	}

	# logconfig
	if (exists $cfg->{logconfig} and ref($cfg->{logconfig}) eq 'ARRAY') {
		my $optstring = join(" ", @{$cfg->{logconfig}});
		print $fh "logconfig $optstring\n";
	}

	# monitoring options , see man ntp_mon
	# statsdir, might want to check if dir exists and writeable.
	if ($cfg->{statsdir}) {
		print $fh "\nstatsdir $cfg->{statsdir}\n";
	}

	# statistics
	if ($cfg->{statistics}) {
		my $opts = $cfg->{statistics};
		my @o    = map {
			if ($opts->{$_}) { "$_"; }
		} sort keys %$opts;
		my $optstring = join(" ", @o);
		print $fh "statistics $optstring\n";
	}

	# filegen
	if ($cfg->{filegen}) {
		foreach my $opts (@{$cfg->{filegen}}) {
			my @opts = grep { !/name|file/ } sort keys %{$opts};
			my @o    = map  { "$_ $opts->{$_}" } @opts;
			my $optstring = join(" ", @o);
			print $fh sprintf("filegen %s file %s %s\n", $opts->{name}, $opts->{file}, $optstring);
		}
	}

	return $fh->close();
}

sub needs_restarting {
	my ($self, $ntpconf_ret, $ntpstep_ret) = @_;

	return $ntpconf_ret || $ntpstep_ret;
}

sub restart_service_ntpd {
	my ($self, $cfg) = @_;

	# get service name if this is set in configuration.
	# otherwise set default for solaris or linux
	my $servicename;
	if (exists $cfg->{servicename}) {
		$servicename = $cfg->{servicename};
	} elsif ($^O eq 'solaris') {
		$servicename = $DEFAULTSOL_SERVICE;
	} else {
		$servicename = $DEFAULT_SERVICE;
	}

	# build restart service command base on os
	my $restart_cmd;
	if ($^O eq 'solaris') {
		$restart_cmd = "/sbin/svcadm restart $servicename";
	} else {
		$restart_cmd = "/sbin/service $servicename restart";
	}

	$self->debug(3,"restarting ntpd deamon");
	CAF::Process->new([$restart_cmd], log => $self)->run();
	$self->info('restarted ${project.artifactId} after config file changes');

	return;
}

sub Unconfigure {
	my ($self, $config) = @_;

	$self->info('nothing done to unconfigure ${project.artifactId}');

	return;
}

1;    #required for Perl modules
