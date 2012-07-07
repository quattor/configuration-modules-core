# ${license-info}
# ${developer-info}
# ${author-info}

#
# ntpd - NCM ntpd configuration component
#
# Configure the ntp time daemon
#
################################################################################

package NCM::Component::ntpd;

#
# a few standard statements, mandatory for all components
#

use strict;
use LC::Check;
use NCM::Check;
use NCM::Component;
use Socket;
use Sys::Hostname;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

my $compname = "NCM-ntpd";
my $mypath = '/software/components/ntpd/';

##########################################################################
sub Configure {
##########################################################################

  my ($self,$config)=@_;

  # 'chkconfig' ntpd on for certain runlevels, by default it is off
  #
  my $chkconfig_current = `/sbin/chkconfig --list ntpd`;
  if ($chkconfig_current =~ /[345]:off/) {
    if ($NoAction) {
      $self->info("would chkconfig on ntpd");
    } else {
      system("/sbin/chkconfig --level 345 ntpd on");
      $self->info("enabled ntpd (chkconfig)");
    }
  } else {
    $self->debug(1,"ntpd is already enabled for runlevels 3,4,5");
  }

  # Getting the time servers from "/software/components/ntpd/servers"
  # with IP address
  #
  my @TIME_SERVERS;
  my @CLIENT_NETWORKS;
  my $ServerNo = 0;
  my $changes = 0;
  my $nots=0;

  while ($config->elementExists("/software/components/ntpd/servers/".$ServerNo)) {
   my $time_server = $config->getValue("/software/components/ntpd/servers/".$ServerNo);
   $ServerNo++;
   my $ip = gethostbyname($time_server);
   if (!defined($ip)){
      $self->warn("Unknown/unresolvable NTP server ".$time_server." - ignoring!");
      next;
   }
   $nots++;
   $ip = inet_ntoa($ip);
   push @TIME_SERVERS, $ip;
   $self->debug(3, "found NTP server $ip (for $time_server)");
}

if ($nots==0){
   $self->error("No (valid) time server defined");
   return;
}

  if($config->elementExists( $mypath."clientnetworks")) {
    my $clientNo = 0;
    while ($config->elementExists($mypath."clientnetworks/".$clientNo)) {
      if($config->elementExists( $mypath."clientnetworks/".$clientNo."/net") &&
	 $config->elementExists( $mypath."clientnetworks/".$clientNo."/mask")) {
	my $net = $config->getValue($mypath."clientnetworks/".$clientNo."/net");
	my $mask = $config->getValue($mypath."clientnetworks/".$clientNo."/mask");
	$clientNo++;
	push @CLIENT_NETWORKS, [$net, $mask];
	$self->debug(3, "found NTP client net $net/$mask");
      }
    }
  }

  # Declare the name servers in /etc/ntp.conf and /etc/ntp/step-tickers
  #
  my $ntpd_conf = "/etc/ntp.conf";

  if (! -e $ntpd_conf ) {
      $self->warn("config file $ntpd_conf was missing, recreating");
      if (! open(FOO, ">$ntpd_conf")) {
	  $self->error("cannot create $ntpd_conf : $!");
	  return;      
      }
      close(FOO);
  }

  $changes += LC::Check::file($ntpd_conf,
			      source => $ntpd_conf,
 			      code   => sub {
	  my ($contents) = @_;

	   #
	   # Remove restriction in /etc/ntp.conf, "otherwise it won't work"
           $contents =~ s{^\s*(restrict[^\n]*\n)}{}mg
              unless $contents =~ /^\#restrict[^\n]*\n/;

	   #
	   # Remove all defined servers
           $contents =~ s{^\s*server\s+[^\n]*\n}{}mg;

	   #
	   # Remove fudge server
           $contents =~ s{^\s*fudge\s+[^\n]*\n}{}mg;

	   #
	   # Remove our comment
           $contents =~ s{^#.*$compname[^\n]*\n}{}mg;

	   # add back stuff. First our comment
	   $contents .= "# This file is under $compname control.\n";

	   # proper access control - restrictive by default
	   $contents .= "restrict default ignore\n";

	   # configured servers
           for my $server (@TIME_SERVERS) {
              $contents .= "server   $server\n";
	          $contents .= "restrict $server mask 255.255.255.255 nomodify notrap noquery\n";
           }
	   # add localhost in case of network outages
	   $contents .= "fudge    127.127.1.0 stratum 10\n";
           # allow some debugging via ntpdc, but no modifications
	   $contents .= "restrict 127.0.0.1 nomodify notrap\n";

	   # add our own clients in case we are a real "server"
           if (@CLIENT_NETWORKS) {
               $contents .= "server   127.0.0.1\n";
           }
	   for my $client (@CLIENT_NETWORKS) {
	     $contents .= "restrict ".$$client[0]." mask ".$$client[1]." nomodify notrap\n";
	   }

			  return ($contents);
		      },
	  backup => ".old");


  my $tickers = "/etc/ntp/step-tickers";
  if (! -e $tickers ) {
      $self->info("$tickers was missing, recreating");
      if (! open(FOO, ">$tickers")) {
	  $self->error("cannot create $tickers : $!");
	  return;      
      }
      close(FOO);
  }
  $changes += LC::Check::file($tickers,
			      code   => sub {
				  my $contents = join("\n",@TIME_SERVERS)."\n";  # don't care for previous content
				  return ($contents);
			      },
			      backup => ".old");
  


  if ($changes) {  # this makes sure ntpd runs afterwards, i.e. no "condreload"
    system("/sbin/service ntpd reload");
    $self->info("restarted ntpd after config file changes");
  } else {
    $self->debug(1,"no config file changes, no restart required");
  }

}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;

  $self->info("nothing done to unconfigure ntpd");

  return;
}


1; #required for Perl modules
### Local Variables: ///
### mode: perl ///
### End: ///
