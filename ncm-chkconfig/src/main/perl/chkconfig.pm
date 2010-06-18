# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# chkconfig component
#
# NCM chkconfig component
#
#
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::chkconfig;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::chkconfig::NoActionSupported = 1;

use NCM::Check;
use LC::Process qw(run output);

my $chkconfigcmd = "/sbin/chkconfig";
my $servicecmd   = "/sbin/service";

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my $default = 'ignore';
  my %currentservices;
  my %configuredservices;

  my $currentrunlevel;

  if ($config->elementExists('/software/components/chkconfig/default')) {
    $default=$config->getValue('/software/components/chkconfig/default');
  }
  $self->info("default setting for non-specified services: $default");

  %currentservices = $self->get_current_services_hash();

  $currentrunlevel = $self->getcurrentrunlevel();

  my $valPath = '/software/components/chkconfig/service';

  unless($config->elementExists($valPath)) {
      $self->error("cannot get $valPath");
      return;
  }
  my $srvcs = $config->getElement($valPath);

  my @cmdlist;
  my @servicecmdlist;

  while($srvcs->hasNextElement()) {
      
      my $startstop;
      my $cs = $srvcs->getNextElement(); #current service
      my $service = $cs->getName();

      #get startstop value if it exists
      my $servpath = $cs->getPath()->toString();

      if($config->elementExists("$servpath/startstop")) {
	  my $ssel = $config->getElement("$servpath/startstop");
	  $startstop = $ssel->getValue();
      }

      #override the service name to use value of 'name' if it is set
      if($config->elementExists("$servpath/name")) {
	  my $nameel = $config->getElement("$servpath/name");
	  $service = $nameel->getValue();
      }

      # remember about this one for later
      $configuredservices{$service}=1;

      # unfortunately not all combinations make sense. Check for some
      # of the more obvious ones, but eventually we need a single
      # entry per service.

      while($cs->hasNextElement()) {
	  
	  my $opt = $cs->getNextElement();
	  my $optname = lc($opt->getName());
	  my $optval =  lc($opt->getValue());
	  chomp $optval;

	  #6 kinds of entries: on,off,reset,add,del and startstop.
	  if($optname eq 'add' and $optval eq 'true') {
	    if($config->elementExists("$servpath/del")) {
		  $self->warn("service $service has both 'add' and 'del' settings defined, 'del' wins");
	    } elsif($config->elementExists("$servpath/on")) {
		  $self->info("service $service has both 'add' and 'on' settings defined, 'on' implies 'add'");
	    } elsif (! $currentservices{$service} ) {
	      push(@cmdlist, [$chkconfigcmd, "--add", $service]);
	      $self->info("$service: adding to chkconfig");

	      if($startstop and $startstop eq 'true') {
		# this smells broken - shouldn't we check the desired runlevel? At least we no longer do this at install time.
		  push(@servicecmdlist, [$servicecmd, $service, "start"]);
	      }
	    } else {
	      $self->debug(2, "$service is already known to chkconfig, no need to 'add'");
	    }
	  } elsif ($optname eq 'del' and $optval eq 'true') {
	    if ($currentservices{$service} ) {
	      push(@cmdlist, [$chkconfigcmd, $service, "off"]);
	      push(@cmdlist, [$chkconfigcmd, "--del", $service]);
	      $self->info("$service: removing from chkconfig");

	      if($startstop and $startstop eq 'true') {
		push(@servicecmdlist, [$servicecmd, $service, "stop"]);
	      }
	    } else {
	      $self->debug(2, "$service is not known to chkconfig, no need to 'del'");
	    }
		
	  } elsif ($optname eq 'on') { 
	      if($config->elementExists("$servpath/off")) {
		  $self->warn("service $service has both 'on' and 'off' settings defined, 'off' wins");
	      } elsif ($config->elementExists("$servpath/del")) {
		  $self->warn("service $service has both 'on' and 'del' settings defined, 'del' wins");
	      } elsif(!validrunlevels($optval)) {
		  $self->warn("invalid runlevel string $optval defined for ".
			      "option \'$optname\' in service $service, ignoring");
	      } else {
		  if(!$optval) {
		      $optval = '2345'; # default as per doc (man chkconfig)
		      $self->debug(2, "$service: assuming default 'on' runlevels to be $optval");
		  }
		  my $currentlevellist = "";
		  if ($currentservices{$service} ) {
		      for my $i (0.. 6) {
			  if ($currentservices{$service}[$i] eq 'on') {
			      $currentlevellist .= "$i";
			  }
		      }
		  } else {
		      $self->info("$service was not configured, 'add'ing it");
		      push(@cmdlist, [$chkconfigcmd, "--add", $service]);
		  }
		  if ($optval ne $currentlevellist) {
		      $self->info("$service was 'on' for \"$currentlevellist\", new list is \"$optval\"");
		      push(@cmdlist, [$chkconfigcmd, $service, "off"]);
		      push(@cmdlist, [$chkconfigcmd, "--level", $optval,
				      $service, "on"]);
		      if($startstop and $startstop eq 'true'  
			 and ($optval =~ /$currentrunlevel/)) {
			  push(@servicecmdlist,[$servicecmd, $service,
						"start"]);
		      }
		  } else {
		      $self->debug(2, "$service already 'on' for \"$optval\", nothing to do");
		  } 
	      }  
	  } elsif ($optname eq 'off') { 
	      if($config->elementExists("$servpath/del")) {
		  $self->info("service $service has both 'off' and 'del' settings defined, 'del' wins");
	      } elsif(!validrunlevels($optval)) {
		  $self->warn("invalid runlevel string $optval defined for ".
			      "option \'$optname\' in service $service");
	      } else {		   
		  if(!$optval) {
		      $optval = '2345'; # default as per doc (man chkconfig)
		      $self->debug(2, "$service: assuming default 'on' runlevels to be $optval");  # 'on' because this means we have to turn them 'off' here..
		  }
		  my $currentlevellist = "";
		  my $todo = "";
		  if ($currentservices{$service} ) {
		      for my $i (0.. 6) {
			  if ($currentservices{$service}[$i] eq 'off') {
			      $currentlevellist .= "$i";
			  }
		      }
		      for my $s (split('',$optval)) {
			  if ($currentlevellist !~ /$s/) {
			      $todo .="$s";
			  } else {
			      $self->debug(3, "$service: already 'off' for runlevel $s");
			  }
		      }
		  }
		  if ($currentlevellist &&        # do not attempt to turn off a non-existing service
		      $todo &&                    # do nothing if service is already off for everything we'd like to turn off..
		      ($optval ne $currentlevellist)) {
		      $self->info("$service was 'off' for '$currentlevellist', new list is '$optval', diff is '$todo'");
		      push(@cmdlist, [$chkconfigcmd, "--level", $optval,
				      $service, "off"]);
		      if($startstop and $startstop eq 'true'
			 and ($optval =~ /$currentrunlevel/)) {
			  push(@cmdlist, [$servicecmd, $service, "stop"]);
		      }
		  }
	      }
	  } elsif ($optname eq 'reset') {
	      if($config->elementExists("$servpath/del")) {
		  $self->warn("service $service has both 'reset' and 'del' settings defined, 'del' wins");
	      } elsif($config->elementExists("$servpath/off")) {
		  $self->warn("service $service has both 'reset' and 'off' settings defined, 'off' wins");
	      } elsif($config->elementExists("$servpath/on")) {
		  $self->warn("service $service has both 'reset' and 'on' settings defined, 'on' wins");
	      } elsif(validrunlevels($optval)) {
		    # FIXME - check against current?.
		  if($optval) {
		      push(@cmdlist,[$chkconfigcmd, "--level", $optval,
				     $service, "reset"]);
		  } else {
		      push(@cmdlist, [$chkconfigcmd, $service, "reset"]);
		  } 
	      } else {
		  $self->warn("invalid runlevel string $optval defined for ".
			      "option $optname in service $service");
	      }

	  } elsif ($optname eq 'startstop' or $optname eq 'add' or 
		   $optname eq 'del' or $optname eq 'name') {
	      # do nothing
	  } else {
	      $self->error("undefined option name $optname in service $service");
	      return;
	  }
      } #while
  } #while

  # check for leftover services that are known to the machine but not in CDB
  if ($default eq 'off') {
      $self->debug(2,"Looking for other services to turn 'off'");
      for my $oldservice (keys(%currentservices)) {
	  if ($configuredservices{$oldservice}) {
	      $self->debug(2,"$oldservice is explicitly configured, keeping it");
	      next;
	  }
	  # special case "network" and friends, awfully hard to recover from if turned off.. #54376
	  my @services_protected_against_dumb_admin = ('network', 'messagebus', 'haldaemon', 'sshd');
	  if(grep { $oldservice eq $_ } @services_protected_against_dumb_admin)  {
	      $self->warn("cowardly refusing to turn '$oldservice' off via a default setting..");
	      next;
	  }
	  # turn 'em off.
	  if (defined($currentrunlevel) and  $currentservices{$oldservice}[$currentrunlevel] ne 'off' ) {
	      # they supposedly are even active _right now_.
	      $self->debug(2,"$oldservice was not 'off' in current level $currentrunlevel, 'off'ing and 'stop'ping it..");
	      push(@servicecmdlist, [$servicecmd, $oldservice, "stop"]);
	      push(@cmdlist, [$chkconfigcmd, $oldservice, "off"]);
	  } else {
	      # see whether this was non-off somewhere else
	      my $was_on = "";
	      for my $i ((0..6)) {
		  if ( $currentservices{$oldservice}[$i] ne 'off' ) {
		      $self->debug(2,"$oldservice was not 'off' in level $i, 'off'ing it..");
		      $was_on .= $i;
		      last;
		  }
	      }
	      if($was_on) {
		  push(@cmdlist, [$chkconfigcmd, "--level", $was_on,
				  $oldservice, "off"]);
	      } else {
		  $self->debug(2,"$oldservice was already 'off', nothing to do");
	      }
	  }
      }
  }

  
  #perform the "chkconfig" commands 
  for my $cmd (@cmdlist) {
      #info 
      $self->info("executing command: ".join(" ", @$cmd));
      
      unless($NoAction) {
	  my $out = output(@$cmd);
	  if(!defined("$cmd")) {
	      $self->warn("cannot execute ", join(" ", @$cmd));
	  } elsif ($? >> 8) {
	      chomp($out);
	      $self->warn($out);
	  }
      }
  }

  #perform the "service" commands - these need ordering and filtering
  if($currentrunlevel) {
      if ($#servicecmdlist >= 0) {
	  my @filteredservicelist = $self->service_filter(@servicecmdlist);
	  my @orderedservicecmdlist = $self->service_order($currentrunlevel, @filteredservicelist);
	  for my $cmd (@orderedservicecmdlist) {
	      #info 
	      $self->info("executing command: ". join(" ", @$cmd));
	      
	      unless($NoAction) {
		  my $out = output(@$cmd);
		  if(!defined($cmd)) {
		      $self->warn("cannot execute ", join(" ", @$cmd));
		  } elsif ($? >> 8) {
		      chomp($out);
		      $self->warn($out);
		  } 
	      }
	  }
      }
  } else {
      $self->info("not running any 'service' commands at install time.");
  }
  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
}

##########################################################################
sub service_filter {
##########################################################################
# check the proposed "service" actions:
#   drop anything that is already running from being restarted
#   drop anything that isn't from being stopped.
#   relies on 'service bla status' to return something useful (lots don't).
#   If in doubt, we leave the command..
    my $self = shift;
    my @service_actions = @_;
    my $service;
    my $action;
    my @new_actions;
    for my $line (@service_actions) {
        $service = $line->[1];
	$action = $line->[2];
	
	my $current_state=output($servicecmd, $service, 'status');

	if($action eq 'start' && $current_state =~ /is running/s ) {
	    $self->debug(2,"$service already running, no need to '$action'");
	    next;
	} elsif ($action eq 'stop' && $current_state =~ /is stopped/s ) {
	    $self->debug(2,"$service already stopped, no need to '$action'");
	    next;
	} else {	# keep.
	    if( $current_state =~ /is (running|stopped)/s) {  # these are obvious - not the desired state.
		$self->debug(2,"$service: '$current_state', needs '$action'");
	    } else {
		# can't figure out
		$self->info("can't figure out whether $service needs $action from\n$current_state");
	    }
	    push(@new_actions, [$servicecmd, $service, $action]);
	}
    }
    return @new_actions;
}
##########################################################################
sub service_order {
##########################################################################
# order the proposed "service" actions:
#   first stop things, then start. In both cases use the init script order, as shown in /etc/rc.?d/{S|K}numbername
#   Ideally, figure out whether we are booting, and at what priority, and don't do things that will be done anyway..
#   might get some services that need stopping but are no longer registered with chkconfig - these get killed late.

    my $self = shift;
    my $currentrunlevel = shift;
    my @service_actions = @_;
    my @new_actions;
    my @stop_list;
    my @start_list;
    my $bootprio = 999; # FIXME: until we can figure that out
    my $service;
    my $action;

    for my $line (@service_actions) {
        $service = $line->[1];
	$action = $line->[2];
	
	my $prio;
	if($action eq 'stop') {
	    $prio = 99;
	    my @files = glob("/etc/rc".$currentrunlevel.".d/K*$service");
	    if($files[0] =~ m:/K(\d+)$service:) { # assume first file/link, if any.
		$prio = $1;
		$self->debug(3,"found stop prio $prio for $service");
	    } else {
		$self->debug(3,"did not find stop prio for $service, assume $prio");
	    }
	    push (@stop_list, [$prio, $line]);
	} elsif ($action eq 'start') {
	    $prio = 1; # actually, these all should be chkconfiged on!
	    my @files = glob("/etc/rc".$currentrunlevel.".d/S*$service");
	    if($files[0] =~ m:/S(\d+)$service:) { # assume first file/link, if any.
		$prio = $1;
		$self->debug(3,"found start prio $prio for $service");
	    } else {
		$self->warn("did not find start prio for $service, assume $prio");
	    }
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

##########################################################################
sub validrunlevels(\$) {
##########################################################################
    my $str = shift;
    chomp($str);
    
    return 1 unless ($str);

    if($str =~ /^[0-7]+$/) {
	return 1;
    }

    return 0;
}

##########################################################################
sub getcurrentrunlevel($) {
##########################################################################
     my $self = shift;
     my $level = 3;
     if( -x "/sbin/runlevel" ) {
       if(! open(LV, "/sbin/runlevel|")) {
	 $self->error("cannot launch '/sbin/runlevel': $!")
       } else {
	 my $line = <LV>;
	 chomp($line);
	 # N 5
	 if ($line =~ /\w\s(\d)/) {
	   $level = $1;
	   $self->info("current runlevel is $level");
	 } else {
	   $self->info("cannot get runlevel from 'runlevel': $line (during installation?)");  # happens at install time
	   $level=undef;
	 }
       }
     } elsif ( -x "/usr/bin/who" ) {
       if(! open(LV, "/usr/bin/who -r |")) {
	 $self->error("cannot launch '/usr/bin/who -r': $!")
       } else {
	 my $line = <LV>;
	 chomp($line);
	 #          run-level 5  Feb 19 16:08                   last=S
	 if ($line =~ /run-level\s+(\d+)\s/) {
	   $level = $1;
	   $self->info("current runlevel is $level");
	 } else {
	   $self->info("cannot get runlevel from 'who -r': $line (during installation?)");
	   $level=undef;
	 }
       }
     } else {
       $self->warn("no way to determine current runlevel, assuming $level");
     }
     return $level;
}

##########################################################################
# see what is currently configured in terms of services
sub get_current_services_hash($) {
##########################################################################
  my $self = shift;
  my %current;
  if(! open (GET, "$chkconfigcmd --list |")) {
    $self->error("cannot get list of current services from $chkconfigcmd: $!");
    return;
  }
  while(<GET>) {
    # afs       0:off   1:off   2:off   3:off   4:off   5:off   6:off
    # ignore the "xinetd based services"
    if (/^([\w\-]+)\s+0:(\w+)\s+1:(\w+)\s+2:(\w+)\s+3:(\w+)\s+4:(\w+)\s+5:(\w+)\s+6:(\w+)/) {
      $current{$1} = [$2,$3,$4,$5,$6,$7,$8];
    }
  }
  return %current;
}


1; #required for Perl modules

### Local Variables: ///
### mode: perl ///
### End: ///
