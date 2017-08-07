#${PMcomponent}

use parent qw(NCM::Component);

our $EC = LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

use EDG::WP4::CCM::Path 16.8.0 qw(unescape);
use CAF::Process;
use Readonly;

# these won't be turned off with default settings
my %default_protected_services = (
    network => 1,
    messagebus => 1,
    haldaemon => 1,
    sshd => 1,
);

Readonly my $CHKCONFIG_CMD => "/sbin/chkconfig";
Readonly my $SERVICE_CMD => "/sbin/service";
Readonly my $RUNLEVEL_CMD => "/sbin/runlevel";
Readonly my $WHO_CMD => "/usr/bin/who";

Readonly my $DEFAULT_NONSPEC_DEFAULT => 'ignore';

sub Configure
{
    my ($self, $config)=@_;

    my (%configuredservices, @cmdlist, @servicecmdlist);

    my $tree = $config->getTree($self->prefix());

    my $default = $tree->{default} || $DEFAULT_NONSPEC_DEFAULT;
    $self->verbose("Default setting for non-specified services: $default");

    my %currentservices = $self->get_current_services_hash();

    my $currentrunlevel = $self->getcurrentrunlevel();

    foreach my $escservice (sort keys %{$tree->{service}}) {
        my $detail = $tree->{service}->{$escservice};
        my ($service, $startstop);

        # get startstop value if it exists
        $startstop = $detail->{startstop} if (exists($detail->{startstop}));

        # override the service name to use value of 'name' if it is set
        if (exists($detail->{name})) {
            $service = $detail->{name};
        } else {
            $service = unescape($escservice);
        }

        # remember about this one for later
        $configuredservices{$service} = 1;

        # unfortunately not all combinations make sense. Check for some
        # of the more obvious ones, but eventually we need a single
        # entry per service.
        foreach my $optname (sort keys %$detail) {
            my $optval = $detail->{$optname};
            my $msg = "$service: ";

            # 6 kinds of entries: on,off,reset,add,del and startstop.
            if ($optname eq 'add' && $optval) {
                if (exists($detail->{del})) {
                    $self->warn("Service $service has both 'add' and 'del' settings defined, 'del' wins");
                } elsif ($detail->{on}) {
                    $self->info("Service $service has both 'add' and 'on' settings defined, 'on' implies 'add'");
                } elsif (! $currentservices{$service} ) {
                    $msg .= "adding to chkconfig";
                    push(@cmdlist, [$CHKCONFIG_CMD, "--add", $service]);

                    if ($startstop) {
                        # this smells broken - shouldn't we check the desired runlevel? At least we no longer do this at install time.
                        $msg .= " and starting";
                        push(@servicecmdlist, [$SERVICE_CMD, $service, "start"]);
                    }
                    $self->info($msg);
                } else {
                    $self->debug(2, "$service is already known to chkconfig, but running 'reset'");
                    push(@cmdlist, [$CHKCONFIG_CMD, $service, "reset"]);
                }
            } elsif ($optname eq 'del' && $optval) {
                if ($currentservices{$service} ) {
                    $msg .= "removing from chkconfig";
                    push(@cmdlist, [$CHKCONFIG_CMD, $service, "off"]);
                    push(@cmdlist, [$CHKCONFIG_CMD, "--del", $service]);

                    if ($startstop) {
                        $msg .= " and stopping";
                        push(@servicecmdlist, [$SERVICE_CMD, $service, "stop"]);
                    }
                    $self->info($msg);
                } else {
                    $self->debug(2, "$service is not known to chkconfig, no need to 'del'");
                }
            } elsif ($optname eq 'on') {
                if (exists($detail->{off})) {
                    $self->warn("Service $service has both 'on' and 'off' settings defined, 'off' wins");
                } elsif (exists($detail->{del})) {
                    $self->warn("Service $service has both 'on' and 'del' settings defined, 'del' wins");
                } elsif (!$self->validrunlevels($optval)) {
                    $self->warn("Invalid runlevel string $optval defined for ".
                                "option \'$optname\' in service $service, ignoring");
                } else {
                    if (!$optval) {
                        $optval = '2345'; # default as per doc (man chkconfig)
                        $self->debug(2, "$service: assuming default 'on' runlevels to be $optval");
                    }
                    my $currentlevellist = "";
                    if ($currentservices{$service} ) {
                        foreach my $i (0.. 6) {
                            if ($currentservices{$service}[$i] eq 'on') {
                                $currentlevellist .= "$i";
                            }
                        }
                    } else {
                        $self->info("$service was not configured, 'add'ing it");
                        push(@cmdlist, [$CHKCONFIG_CMD, "--add", $service]);
                    }
                    if ($optval ne $currentlevellist) {
                        $msg .= "was 'on' for \"$currentlevellist\", new list is \"$optval\"";
                        push(@cmdlist, [$CHKCONFIG_CMD, $service, "off"]);
                        push(@cmdlist, [$CHKCONFIG_CMD, "--level", $optval, $service, "on"]);
                        if ($startstop && ($optval =~ /$currentrunlevel/)) {
                            $msg .= " ; and starting";
                            push(@servicecmdlist,[$SERVICE_CMD, $service, "start"]);
                        }
                        $self->info($msg);
                    } else {
                        $self->debug(2, "$service already 'on' for \"$optval\", nothing to do");
                    }
                }
            } elsif ($optname eq 'off') {
                if (exists($detail->{del})) {
                    $self->info("service $service has both 'off' and 'del' settings defined, 'del' wins");
                } elsif (!$self->validrunlevels($optval)) {
                    $self->warn("Invalid runlevel string $optval defined for ".
                                "option \'$optname\' in service $service");
                } else {
                    if (!$optval) {
                        $optval = '2345'; # default as per doc (man chkconfig)
                        # 'on' because this means we have to turn them 'off' here.
                        $self->debug(2, "$service: assuming default 'on' runlevels to be $optval");
                    }
                    my $currentlevellist = "";
                    my $todo = "";
                    if ($currentservices{$service}) {
                        foreach my $i (0.. 6) {
                            if ($currentservices{$service}[$i] eq 'off') {
                                $currentlevellist .= "$i";
                            }
                        }
                        foreach my $s (split('', $optval)) {
                            if ($currentlevellist !~ /$s/) {
                                $todo .="$s";
                            } else {
                                $self->debug(3, "$service: already 'off' for runlevel $s");
                            }
                        }
                    }
                    if ($currentlevellist && # do not attempt to turn off a non-existing service
                            $todo &&         # do nothing if service is already off for everything we'd like to turn off.
                            ($optval ne $currentlevellist)) {
                        $msg .= "was 'off' for '$currentlevellist', new list is '$optval', diff is '$todo'";
                        push(@cmdlist, [$CHKCONFIG_CMD, "--level", $optval, $service, "off"]);
                        if ($startstop and ($optval =~ /$currentrunlevel/)) {
                            $msg .= "; and stopping";
                            push(@cmdlist, [$SERVICE_CMD, $service, "stop"]);
                        }
                        $self->info($msg);
                    }
                }
            } elsif ($optname eq 'reset') {
                if (exists($detail->{del})) {
                    $self->warn("service $service has both 'reset' and 'del' settings defined, 'del' wins");
                } elsif (exists($detail->{off})) {
                    $self->warn("service $service has both 'reset' and 'off' settings defined, 'off' wins");
                } elsif (exists($detail->{on})) {
                    $self->warn("service $service has both 'reset' and 'on' settings defined, 'on' wins");
                } elsif ($self->validrunlevels($optval)) {
                    # FIXME - check against current?.
                    $msg .= 'chkconfig reset';
                    if ($optval) {
                        push(@cmdlist,[$CHKCONFIG_CMD, "--level", $optval, $service, "reset"]);
                    } else {
                        push(@cmdlist, [$CHKCONFIG_CMD, $service, "reset"]);
                    }
                    $self->info($msg);
                } else {
                    $self->warn("Invalid runlevel string $optval defined for ".
                                "option $optname in service $service");
                }
            } elsif ($optname eq 'startstop' or $optname eq 'add' or
                     $optname eq 'del' or $optname eq 'name') {
                # do nothing
            } else {
                $self->error("Undefined option name $optname in service $service");
                return;
            }
        } # foreach detail
    } # foreach service

    # check for leftover services that are known to the machine but not in template
    if ($default eq 'off') {
        $self->debug(2,"Looking for other services to turn 'off'");
        foreach my $oldservice (sort keys %currentservices) {
            if ($configuredservices{$oldservice}) {
                $self->debug(2,"$oldservice is explicitly configured, keeping it");
                next;
            }
            # special case "network" and friends, awfully hard to recover from if turned off. #54376
            if (exists($default_protected_services{$oldservice}))  {
                $self->warn("default_protected_services: refusing to turn '$oldservice' off via a default setting.");
                next;
            }
            # turn 'em off.
            if (defined($currentrunlevel) and  $currentservices{$oldservice}[$currentrunlevel] ne 'off' ) {
                # they supposedly are even active _right now_.
                $self->debug(2,"$oldservice was not 'off' in current level $currentrunlevel, 'off'ing and 'stop'ping it.");
                $self->info("$oldservice: oldservice stop and chkconfig off");
                push(@servicecmdlist, [$SERVICE_CMD, $oldservice, "stop"]);
                push(@cmdlist, [$CHKCONFIG_CMD, $oldservice, "off"]);
            } else {
                # see whether this was non-off somewhere else
                my $was_on = "";
                foreach my $i ((0..6)) {
                    if ( $currentservices{$oldservice}[$i] ne 'off' ) {
                        $was_on .= $i;
                    }
                }
                if ($was_on) {
                    $self->debug(2,"$oldservice was not 'off' in levels $was_on, 'off'ing it..");
                    push(@cmdlist, [$CHKCONFIG_CMD, "--level", $was_on, $oldservice, "off"]);
                } else {
                    $self->debug(2,"$oldservice was already 'off', nothing to do");
                }
            }
        }
    }

    #perform the "chkconfig" commands
    $self->run_and_warn(\@cmdlist);

    #perform the "service" commands - these need ordering and filtering
    if($currentrunlevel) {
        if ($#servicecmdlist >= 0) {
            my @filteredservicelist = $self->service_filter(@servicecmdlist);
            my @orderedservicecmdlist = $self->service_order($currentrunlevel, @filteredservicelist);
            $self->run_and_warn(\@orderedservicecmdlist);
        }
    } else {
        $self->info("Not running any 'service' commands at install time.");
    }

    return 1;
}

# check the proposed "service" actions:
#   drop anything that is already running from being restarted
#   drop anything that isn't from being stopped.
#   relies on 'service bla status' to return something useful (lots don't).
#   If in doubt, we leave the command..
sub service_filter
{
    my ($self, @service_actions) = @_;

    my ($service, $action, @new_actions);
    foreach my $line (@service_actions) {
        $service = $line->[1];
        $action = $line->[2];

        my $current_state = CAF::Process->new([$SERVICE_CMD, $service, 'status'], log => $self, keeps_state => 1)->output();

        if ($action eq 'start' && $current_state =~ /is running/s ) {
            $self->debug(2,"$service already running, no need to '$action'");
        } elsif ($action eq 'stop' && $current_state =~ /is stopped/s ) {
            $self->debug(2,"$service already stopped, no need to '$action'");
        } else {    # keep.
            if( $current_state =~ /is (running|stopped)/s) {  # these are obvious - not the desired state.
                $self->debug(2,"$service: '$current_state', needs '$action'");
            } else {
                # can't figure out
                $self->info("Can't figure out whether $service needs $action from\n$current_state");
            }
            push(@new_actions, [$SERVICE_CMD, $service, $action]);
        }
    }
    return @new_actions;
}

# order the proposed "service" actions:
#   first stop things, then start. In both cases use the init script order, as shown in /etc/rc.?d/{S|K}numbername
#   Ideally, figure out whether we are booting, and at what priority, and don't do things that will be done anyway..
#   might get some services that need stopping but are no longer registered with chkconfig - these get killed late.
sub service_order
{
    my ($self, $currentrunlevel, @service_actions) = @_;

    my (@new_actions, @stop_list, @start_list, $service, $action);
    my $bootprio = 999; # FIXME: until we can figure that out

    foreach my $line (@service_actions) {
        $service = $line->[1];
        $action = $line->[2];

        my ($prio,$serviceprefix);
        if ($action eq 'stop') {
            $prio = 99;
            $serviceprefix = 'K';
        } elsif ($action eq 'start') {
            $prio = 1; # actually, these all should be chkconfiged on!
            $serviceprefix = 'S';
        }

        my $globtxt = "/etc/rc$currentrunlevel.d/$serviceprefix*$service";
        my @files = glob($globtxt);
        my $nrfiles = scalar(@files);
        if ($nrfiles == 0) {
            $self->warn("No files found matching $globtxt");
        } elsif ($nrfiles > 1) {
            $self->warn("$nrfiles files found matching $globtxt, using first one.".
                        " List: ".join(',',@files));
        }
        if ($nrfiles && $files[0] =~ m:/$serviceprefix(\d+)$service:) { # assume first file/link, if any.
            $prio = $1;
            $self->debug(3,"Found $action prio $prio for $service");
        } else {
            $self->warn("Did not find $action prio for $service, assume $prio");
        }


        if ($action eq 'stop') {
            push (@stop_list, [$prio, $line]);
        } elsif ($action eq 'start') {
            if ($prio < $bootprio) {
                push (@start_list, [$prio, $line]);
            } else {
                $self->debug(3, "dropping '$line' since will come later in boot - $prio is higher than current $bootprio");
            }
        }
    }

    # so we've got both lists, with [priority,command]. just sort them, drop the "priority" column, and concat.
    @new_actions = map { $$_[1] } sort { $$a[0] <=> $$b[0] } @stop_list;
    push (@new_actions , map { $$_[1] } sort { $$a[0] <=> $$b[0] } @start_list);

    return @new_actions;
}

sub validrunlevels
{
    my ($self, $str) = @_;

    chomp($str);

    return 1 unless ($str);

    if ($str =~ /^[0-7]+$/) {
        return 1;
    }

    return 0;
}


sub getcurrentrunlevel
{
    my $self = shift;

    my $level = 3;
    if (-x $RUNLEVEL_CMD) {
        my $line = CAF::Process->new([$RUNLEVEL_CMD], log => $self, keeps_state => 1)->output();
        chomp($line);
        # N 5
        if ($line && $line =~ /\w+\s+(\d+)/) {
            $level = $1;
            $self->info("Current runlevel is $level");
        } else {
            $self->warn("Cannot get runlevel from 'runlevel': $line (during installation?) (exitcode $?)");  # happens at install time
            $level=undef;
        }
    } elsif (-x $WHO_CMD) {
        my $line = CAF::Process->new([$WHO_CMD, "-r"],log => $self, keeps_state => 1)->output();
        chomp($line);
        #          run-level 5  Feb 19 16:08                   last=S
        if ($line && $line =~ /run-level\s+(\d+)\s/) {
            $level = $1;
            $self->info("Current runlevel is $level");
        } else {
            $self->warn("Cannot get runlevel from 'who -r': $line (during installation?) (exitcode $?)");
            $level=undef;
        }
    } else {
        $self->warn("No way to determine current runlevel, assuming $level");
    }
    return $level;
}


# see what is currently configured in terms of services
sub get_current_services_hash
{
    my $self = shift;

    my %current;
    my $data = CAF::Process->new([$CHKCONFIG_CMD, '--list'], log => $self, keeps_state => 1)->output();

    if ($?) {
        $self->error("Cannot get list of current services from $CHKCONFIG_CMD --list: $!");
        return;
    } else {
        foreach my $line (split(/\n/,$data)) {
            # afs       0:off   1:off   2:off   3:off   4:off   5:off   6:off
            # ignore the "xinetd based services"
            if ($line =~ m/^([\w\-]+)\s+0:(\w+)\s+1:(\w+)\s+2:(\w+)\s+3:(\w+)\s+4:(\w+)\s+5:(\w+)\s+6:(\w+)/) {
                $current{$1} = [$2,$3,$4,$5,$6,$7,$8];
            }
        }
    }
    return %current;
}


sub run_and_warn
{
    my ($self, $cmdlistref) = @_;

    foreach my $cmd (@$cmdlistref) {
        my $out = CAF::Process->new($cmd, log => $self)->output();
        if ($?) {
            chomp($out);
            $self->warn("Exitcode $?, output $out");
        }
    }
}

1;
