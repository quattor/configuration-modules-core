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
use CAF::Process;

local(*DTA);

# Define paths for convenience. 
my $base = "/software/components/named";

my $true = "true";
my $false = "false";

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  # Get config into a perl Hash
  my $named_config = $config->getElement($base)->getTree();
  
  # Check if named server must be enabled

  my $server_enabled = 0;
  if ( $named_config{start} ) {
    $server_enabled = 1;
  }


  # Update resolver configuration file with appropriate servers
  if ( $named_config{servers} || $server_enabled ) {
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
                                                  for my $named_server (@{$named_config{servers}] {
                                                    push @newcontents, "nameserver $named_server\t\t# added by Quattor"
                                                  }
                                                  return(join "\n",@newcontents);
                                                 }
                                  );
    if ( $named_config{search} ) {
      my @domains;
      for my $domain (@{$named_config{search}}) {
        push @domains, $domain;
      }
      if ( @domains ){
        $changes += NCM::Check::lines("/etc/resolv.conf",
                                       linere => "^\\s*search\\s*.*",
                                       goodre => "^\\s*search\\s*@domains",
                                       good   => "search @domains");
      }
    }
    
    # options
    if ( $named_config{options} ) {
      my @options;
      for my $option (@{$named_config{options}}) {
        push @options, $option;
      }
      if ( @options ){
        $changes += NCM::Check::lines("/etc/resolv.conf",
                                       linere => "^\\s*options\\s*.*",
                                       goodre => "^\\s*options\\s*@options",
                                       good   => "options @options");
      }
    }

    unless (defined($changes)) {
      $self->error('error modifying /etc/resolv.conf');
      return;
    }
  }

  # Ignore named startup configuration if startup script is not present (service not configured)

  my $service = "named";
  my $cmd = CAF::Process->new(["/sbin/chkconfig --list $service"], log => $self);
  $cmd->output();      # Also execute the command
  unless ( $? ) {
    $self->debug(1,"Service $service doesn't exist on current host. Skipping $service configuration.");
    return(1);
  }

  # Copy the correct config file into /etc if specified, 
  # else use current configuration file

  my $server_changes;
  if ( $named_config{configfile} ) {
      $self->info("Checking $service configuration (/etc/named.conf)...");
      $server_changes = LC::Check::file("/etc/named.conf",
                                     source      => $named_config{configfile},
                                     destination => "/etc/named.conf",
                                     owner       => 0,
                                     mode        => 0644
                                   );
      unless (defined($server_changes)) {
        $self->error('error modifying /etc/named.conf');
      return;
  }
  
  # Enable named service
  
  my $reboot_state;  
  if ( $server_enabled ) {
    $self->info("Enabling service $named...");
    $reboot_state = "on";
  } else {
    $self->info("Disabling service $named...");
    $reboot_state = "off";
  }
  my $cmd = CAF::Process->new(["/sbin/chkconfig --level 345 $service $state"], log => $self);
  $cmd->output();      # Also execute the command
  if ( $? ) {
    $self->error("Error defining service $service state for next reboot.");
  }

  # Start named if enabled and not yet started.
  # Stop named if running but disabled.
  # Restart after a configuration change if enabled and started.

  $self->debug(1,"Checking if service $service is started...");
  my $named_started = 1;
  $cmd = CAF::Process->new(["/sbin/service $service status"], log => $self);
  $cmd->output();      # Also execute the command
  unless ( $? ) {
    $self->debug(1,"Service $service not running.");
    $named_started = 0;
  }
  
  my $action;
  if ( $server_enabled ) {
    if ( ! $named_started ) {
      $action = 'start';
    } else if ( $changes) {
      $action = 'restart';
    }
  } else {
    if ( $named_started ) {
      $action = 'stop';
    };
  }
  
  if ( $action ) {
    $self->info("Doing a $action of service $service...");
    $cmd = CAF::Process->new(["/sbin/service $service $action"], log => $self);
    my $cmd_output = $cmd->output();      # Also execute the command
    unless ( $? ) {
      $self->debug(1,"Failed to update service $service state.\nError message: $cmd_output");
      $named_started = 0;
    }
  } else {
    $self->info("No need to start/stop/restart service $named");
  }
  

  return;
}

1; #required for Perl modules
