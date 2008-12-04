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

use NCM::Check;
use LC::Process qw(run);

my $chkconfigcmd = "/sbin/chkconfig";
my $servicecmd   = "/sbin/service";

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my $default = 'ignore';
  my %currentservices;
  my %configuredservices;

  my $currentrunlevel = 0;

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

      while($cs->hasNextElement()) {
	  
	  my $opt = $cs->getNextElement();
	  my $optname = lc($opt->getName());
	  my $optval =  lc($opt->getValue());
	  chomp $optval;

	  #6 kinds of entries: on,off,reset,add,del and startstop.
	  if($optname eq 'add' and $optval eq 'true') {
	    if (! $currentservices{$service} ) {
	      push @cmdlist, "$chkconfigcmd --add $service";
	      $self->info("$service: adding to chkconfig");

	      if($startstop and $startstop eq 'true') {
		# FIXME: this smells broken - shouldn't we check the desired runlevel?
		  push @cmdlist, "$servicecmd $service start";
	      }
	    } else {
	      $self->debug(2, "$service is already known to chkconfig, no need to 'add'");
	    }
	  } elsif ($optname eq 'del' and $optval eq 'true') {
	    if ($currentservices{$service} ) {
	      push @cmdlist, "$chkconfigcmd --del $service";
	      $self->info("$service: removing from chkconfig");

	      if($startstop and $startstop eq 'true') {
		push @cmdlist, "$servicecmd $service stop";
	      }
	    } else {
	      $self->debug(2, "$service is not known to chkconfig, no need to 'del'");
	    }
		
	  } elsif ($optname eq 'on') { 
	      if(validrunlevels($optval)) {
		  if($optval) {
		    # FIXME - check against current, if anything on right now dont "on" again.
		      push @cmdlist, "$chkconfigcmd --level $optval $service on";

		  } else {
		      push @cmdlist, "$chkconfigcmd $service on";
		  } 		  

		  if($startstop and $startstop eq 'true'  
		     and ((!$optval) or ($optval =~ /$currentrunlevel/))) {
		      push @cmdlist, "$servicecmd $service start";
		  }

	      } else { 
		  $self->warn("invalid runlevel string $optval defined for ".
			      "option \'$optname\' in service $service");
	      }
	     
	  } elsif ($optname eq 'off') { 
	      if(validrunlevels($optval)) {
		    # FIXME - check against current, if anything off right now dont "off" again.
		  if($optval) {
		      push @cmdlist, "$chkconfigcmd --level $optval $service off";
		  } else {
		      push @cmdlist, "$chkconfigcmd $service off";
		  } 

		  if($startstop and $startstop eq 'true'
		     and ((!$optval) or ($optval =~ /$currentrunlevel/))) {
		      push @cmdlist, "$servicecmd $service stop";
		  }
	      } else {
 		  $self->warn("invalid runlevel string $optval defined for ".
			      "option \'$optname\' in service $service");
	      }

	  } elsif ($optname eq 'reset') {
	      if(validrunlevels($optval)) {
		    # FIXME - check against current?.
		  if($optval) {
		      push @cmdlist, "$chkconfigcmd --level $optval $service reset";
		  } else {
		      push @cmdlist, "$chkconfigcmd $service reset";
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
    for my $oldservice (keys(%currentservices)) {
      if ($configuredservices{$oldservice}) {
	$self->debug(2,"$oldservice is explicitly configured");
	next;
      }
      # turn 'em off.
      if ( $currentservices{$oldservice}[$currentrunlevel] ne 'off' ) {
	# they supposedly are even active _right now_.
	$self->debug(2,"$oldservice  was not off in current level $currentrunlevel, stopping it..");
	push @cmdlist, "$servicecmd $oldservice stop";
        push @cmdlist, "$chkconfigcmd $oldservice off";
      } else {
        # see whether this was non-off somewhere else
        my $was_on = 0;
        for my $i ((0..6)) {
          if ( $currentservices{$oldservice}[$i] ne 'off' ) {
	    $self->debug(2,"$oldservice  was not off in level $i, offing it..");
            $was_on=1;
            last;
          }
        }
        if($was_on) {
          push @cmdlist, "$chkconfigcmd $oldservice off";
        } else {
          $self->debug(2,"$oldservice was already off, nothing to do");
        }
      }
    }
  }

  
  #perform the commands 
  for my $cmd (@cmdlist) {
      #info 
      $self->info("executing command: $cmd");
      
      unless($NoAction) {
	  unless(run("$cmd")) {
	      $self->warn("cannot execute $cmd");
	  } 
      }
  }
  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
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
	   $self->warn("cannot get runlevel from 'runlevel': $line");
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
	   $self->warn("cannot get runlevel from 'who -r': $line");
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
    if (/^(\w+)\s+0:(\w+)\s+1:(\w+)\s+2:(\w+)\s+3:(\w+)\s+4:(\w+)\s+5:(\w+)\s+6:(\w+)/) {
      $current{$1} = [$2,$3,$4,$5,$6,$7,$8];
    }
  }
  return %current;
}


1; #required for Perl modules

### Local Variables: ///
### mode: perl ///
### End: ///
