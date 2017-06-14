#${PMcomponent}

=head1 NAME

NCM::ntpd - NCM ntpd configuration component

=head1 SYNOPSIS

This component configures the ntpd (Network Time Protocol) server.
If anything changed in the configuration, it will restart ntpd.

=cut

use parent qw(NCM::Component);

use LC::Exception;

use Socket;
use Sys::Hostname;
use CAF::FileWriter;
use CAF::Service;
use Readonly;

Readonly::Scalar my $COMPNAME => 'ncm-${project.artifactId}';

Readonly::Scalar my $DEFAULT_SERVICE    => '${project.artifactId}';
Readonly::Scalar my $DEFAULTSOL_SERVICE => 'svc:/network/ntp';

Readonly::Scalar our $NTPDCONF    => '/etc/ntp.conf';
Readonly::Scalar our $STEPTICKERS => '/etc/ntp/step-tickers';

our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

sub Configure
{
    my ($self, $config) = @_;

    # Getting the time servers from "/software/components/ntpd/servers"
    # with IP address
    #
    my (@ntp_servers, @client_networks, @candidates);

    my $cfg = $config->getTree($self->prefix());

    # look for legacy-style servers
    if ($cfg->{servers}) {
        foreach my $time_server (@{$cfg->{servers}}) {
            push(@candidates, [$time_server, $cfg->{defaultoptions}]);
        }
    }

    # look for serverlist (with options)
    if ($cfg->{serverlist}) {
        foreach my $time_server_def (@{$cfg->{serverlist}}) {
            push(@candidates, [
                     $time_server_def->{server},
                     $time_server_def->{options} || $cfg->{defaultoptions}
                 ]);
        }
    }

    # @candidates is an array with each element an arrayref (timeserver, options)
    foreach my $ts (@candidates) {
        my $server = $ts->[0];
        my $ip = gethostbyname($server);
        if (!defined $ip) {
            $self->warn("Unknown/unresolvable NTP server $server - ignoring!");
            next;
        }

        $ip = inet_ntoa($ip);
        push(@ntp_servers, {
            server_address => $cfg->{useserverip} ? $ip : $server,
            server_options => $ts->[1],
             });

        $self->debug(3, "found NTP server $ip (for $server)");
    }

    unless (@ntp_servers) {
        $self->error("No (valid) ntp server(s) defined");
        return 0;
    }

    if (exists $cfg->{clientnetworks} && ref($cfg->{clientnetworks}) eq 'ARRAY') {
        foreach my $client (@{$cfg->{clientnetworks}}) {
            if (exists $client->{net} && exists $client->{mask}) {
                push(@client_networks, [$client->{net}, $client->{mask}]);
                $self->debug(3, "found NTP client net $client->{net}/$client->{mask}");
            }
        }
    }

    my $fh_opts = {
        log    => $self,
        mode   => oct(644),
        backup => '.old',
    };
    if ($cfg->{group}) {
        $self->verbose("group $cfg->{group} configured, restricting owner/group/mode");
        $fh_opts->{owner} = 'root';
        $fh_opts->{group} = $cfg->{group};
        $fh_opts->{mode} = oct(640);
    }

    # Declare the ntp servers in /etc/ntp.conf and /etc/ntp/step-tickers
    my $ntpconf_changed = $self->write_ntpd_config($cfg, \@ntp_servers, \@client_networks, $fh_opts);
    my $ntpstep_changed = $self->write_ntpd_step_tickers($cfg, \@ntp_servers, $fh_opts);

    # Restart the daemon if necessary.
    if ( $self->needs_restarting($ntpconf_changed, $ntpstep_changed) ) {
        $self->restart_service_ntpd($cfg);
    } else {
        $self->debug(1, 'no config file changes, no restart of ${project.artifactId} required');
    }

    return 1;
}

sub write_ntpd_step_tickers
{
    my ($self, $cfg, $ntp_servers, $fh_opts) = @_;

    my $stfh = CAF::FileWriter->new($STEPTICKERS, %$fh_opts);

    if (@{$ntp_servers}) {
        print $stfh map { $_->{server_address} . "\n" } @{$ntp_servers};
    }

    return $stfh->close();
}


sub write_ntpd_config
{
    my ($self, $cfg, $ntp_servers, $client_networks, $fh_opts) = @_;

    my $fh = CAF::FileWriter->new($NTPDCONF, %$fh_opts);

    print $fh "# This file is under $COMPNAME control.\n";

    if ($cfg->{restrictdefault}) {
        my $opts = $cfg->{restrictdefault};
        my @o = map {
            if ($_ =~ m/mask/i) { "$_ $opts->{$_}"; }
            elsif ($opts->{$_}) { "$_"; }
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
        } else {
            print $fh "\nincludefile $cfg->{includefile}\n";
        }
    }

    # tinker
    if (exists $cfg->{tinker} && ref($cfg->{tinker}) eq 'HASH') {
        my $opts = $cfg->{tinker};
        my @o = map { "$_ $opts->{$_}"; } sort keys %$opts;
        my $optstring = join(" ", @o);
        print $fh "tinker $optstring\n";
    }

    # enable system options
    if (exists $cfg->{enable} && ref($cfg->{enable}) eq 'HASH') {
        my $opts = $cfg->{enable};
        my @o = map {
            if ($opts->{$_}) { "$_"; }
        } sort keys %$opts;
        my $optstring = join(" ", @o);
        print $fh "enable $optstring\n";
    }

    # disable system options
    if (exists $cfg->{disable} && ref($cfg->{disable}) eq 'HASH') {
        my $opts = $cfg->{disable};
        my @o = map {
            if ($opts->{$_}) { "$_"; }
        } sort keys %$opts;
        my $optstring = join(" ", @o);
        print $fh "disable $optstring\n";
    }

    print $fh "\n# Servers\n";

    # configured servers
    foreach my $ntp_server (@{$ntp_servers}) {
        my $ip = $ntp_server->{server_address};
        my $opts = $ntp_server->{server_options};
        my @o = ();
        if (ref($opts) eq 'HASH') {
            @o = map {
                if ($_ =~ m/maxpoll|minpoll|key|version/i) {
                    "$_ $opts->{$_}";
                } elsif ($opts->{$_}) {
                    "$_";
                }
            } sort keys %$opts;
        }
        my $optstring = join(" ", @o);
        print $fh "server   $ip $optstring\n";
        print $fh "restrict $ip mask 255.255.255.255 nomodify notrap noquery\n";
    }

    # default is to include
    $cfg->{includelocalhost} = 1 unless (exists $cfg->{includelocalhost});

    if (exists $cfg->{includelocalhost}) {
        print $fh "\n# add localhost in case of network outages\n";
        print $fh "fudge    127.127.1.0 stratum 10\n";
    }

    # default is to enable
    $cfg->{enablelocalhostdebug} = 1 unless (exists $cfg->{enablelocalhostdebug});

    if ($cfg->{enablelocalhostdebug}) {
        print $fh "\n# Allow some debugging via ntpdc, but no modifications\n";
        print $fh "restrict 127.0.0.1 nomodify notrap\n";
        print $fh "restrict ::1 nomodify notrap\n";
    }

    # add our own clients in case we are a real "server"
    if (@{$client_networks}) {
        print $fh "server 127.0.0.1\n";
    }
    foreach my $client (@{$client_networks}) {
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
        my @o = map {
            if ($opts->{$_}) { "$_"; }
        } sort keys %$opts;
        my $optstring = join(" ", @o);
        print $fh "statistics $optstring\n";
    }

    # filegen
    if ($cfg->{filegen}) {
        foreach my $opts (@{$cfg->{filegen}}) {
            my @opts = grep { !/name|file/ } sort keys %{$opts};
            my @o = map { "$_ $opts->{$_}" } @opts;
            my $optstring = join(" ", @o);
            print $fh sprintf("filegen %s file %s %s\n", $opts->{name}, $opts->{file}, $optstring);
        }
    }

    return $fh->close();
}

sub needs_restarting
{
    my ($self, $ntpconf_ret, $ntpstep_ret) = @_;

    return $ntpconf_ret || $ntpstep_ret;
}

sub restart_service_ntpd
{
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

    CAF::Service->new([$servicename], log => $self)->restart();
    $self->info('restarted ${project.artifactId} after config file changes');

    return;
}

sub Unconfigure {
    my ($self, $config) = @_;

    $self->info('nothing done to unconfigure ${project.artifactId}');

    return;
}

1;    #required for Perl modules
