# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# named NCM component
#
# NCM named configuration component
#
#
# Copyright (c) 2003 Vladimir Bahyl, CERN and EU DataGrid.
# For license conditions see http://www.eu-datagrid.org/license.html
#
#######################################################################

package NCM::Component::named;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element;

use LC::File qw(copy);
use LC::Check;
use LC::Process qw(run);

local(*DTA);

# Define paths for convenience. 
my $base = "/software/components/named";

my $true = "true";
my $false = "false";

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  # Check if named server must be enabled

  my $server_enabled = 0;
  if ( ($config->elementExists("$base/start")) && ($config->getElement("$base/start")->getValue() eq $true) ) {
    $server_enabled = 1;
  }


  # Update resolver configuration file with appropriate servers
  if ($config->elementExists("$base/servers") || $server_enabled ) {
    my $named_servers;
    if ($config->elementExists("$base/servers")) {
      $named_servers = $config->getElement("$base/servers");
    }
    my $changes += LC::Check::file("/etc/resolv.conf",
				source => "/etc/resolv.conf",
				backup => '.old',
				code   => sub {
				  return() unless @_;
				  my @oldcontents = split /\n/, $_[0];
				  my @newcontents;
				  for my $line (@oldcontents) {
				    if ($line !~ /^\s*nameserver\s+/i) {
				      push @newcontents, $line;
				    }
				  };
				  if ( $server_enabled ) {
				    push @newcontents, "nameserver 127.0.0.1\t\t# added by Quattor"
				  }
				  while ($named_servers->hasNextElement()) {
				    my $named_server = $named_servers->getNextElement()->getValue();
				    push @newcontents, "nameserver $named_server\t\t# added by Quattor"
				  }
				  return(join "\n",@newcontents);
				}
			       );
    if ($config->elementExists("$base/search")) {
      my $search = $config->getElement("$base/search");
      my @domains;
      while ($search->hasNextElement()) {
        push @domains, $search ->getNextElement()->getValue();
      }
      if ( @domains ){
        $changes += NCM::Check::lines("/etc/resolv.conf",
                                       linere => "^\\s*search\\s*.*",
                                       goodre => "^\\s*search\\s*@domains",
                                       good   => "search @domains");
      }
    }
    
    unless (defined($changes)) {
      $self->error('error modifying /etc/resolv.conf');
      return;
    }
  }

  # Ignore named startup configuration if startup script is not present

  if ( -e "/etc/rc.d/init.d/named" ) {
    my $server_state = "stop";
    my $reboot_state = "off";
    if ($server_enabled) {
      $server_state = "restart";     # Use restart rather than start to activate modifications
      $reboot_state = "on";

      # Copy the correct config file into /etc if specified, 
      # else use current configuration file

      if ($config->elementExists("$base/configfile")) {
	my $config_src = $config->getElement("$base/configfile")->getValue();
      
	my $changes += LC::Check::file("/etc/named.conf",
				       source      => $config_src,
				       destination => "/etc/named.conf",
				       owner       => 0,
				       mode        => 0644
				      );
	unless (defined($changes)) {
	  $self->error('error modifying /etc/named.conf');
	return;
	}
      }
    }

    # Make sure, that named will be started/stopped on boot (acccording to 'start')
    unless (LC::Process::run("/sbin/chkconfig named $reboot_state")) {
      $self->error("command \"/sbin/chkconfig named $reboot_state\" failed");
      return;
    }
  
    # Re-restart the named
    unless (LC::Process::run("/sbin/service named $server_state")) {
      $self->error("command \"/sbin/service named $server_state\" failed");
      return;
    }

  } else {
    $self->verbose("named startup script doesn't exist : ignoring named configuration");
  }

  return;
}

1; #required for Perl modules
