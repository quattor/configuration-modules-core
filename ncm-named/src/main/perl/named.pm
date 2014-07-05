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
require Exporter;
our @ISA = qw(NCM::Component Exporter);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use Fcntl qw(SEEK_SET);
use CAF::FileEditor;

use EDG::WP4::CCM::Element;

use Encode qw(encode_utf8);

use LC::File qw(copy);
use LC::Check;
use CAF::Process;

local(*DTA);

# To ease testing
our @EXPORT = qw( NAMED_SYSCONFIG NCM_NAMED_CONFIG_BASE );

# Define paths for convenience.
use constant NAMED_CONFIG_FILE => '/etc/named.conf';
use constant NAMED_SYSCONFIG => '/etc/sysconfig/named';
use constant NCM_NAMED_CONFIG_BASE => "/software/components/named";

my $true = "true";
my $false = "false";

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  # Get config into a perl Hash
  my $named_config = $config->getElement(NCM_NAMED_CONFIG_BASE)->getTree();

  # Check if named server must be enabled

  my $server_enabled;
  if ( defined($named_config->{start}) ) {
    if ( $named_config->{start} ) {
      $server_enabled = 1;
    } else {
      $server_enabled = 0;
    }
  }


  # Update resolver configuration file with appropriate servers
  if ( $named_config->{servers} || ($server_enabled && $named_config->{use_localhost}) ) {
    $self->info("Checking /etc/resolv.conf...");
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
                                                  if ( $server_enabled && $named_config->{use_localhost} ) {
                                                    push @newcontents, "nameserver 127.0.0.1\t\t# added by Quattor"
                                                  }
                                                  for my $named_server (@{$named_config->{servers}}) {
                                                    push @newcontents, "nameserver $named_server\t\t# added by Quattor"
                                                  }
                                                  return(join "\n",@newcontents);
                                                 }
                                  );
    if ( $named_config->{search} ) {
      my @domains;
      for my $domain (@{$named_config->{search}}) {
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
    if ( $named_config->{options} ) {
      my @options;
      for my $option (@{$named_config->{options}}) {
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
  my $cmd = CAF::Process->new(["/sbin/chkconfig", "--list", $service], log => $self);
  $cmd->output();      # Also execute the command
  if ( $? ) {
    $self->debug(1,"Service $service doesn't exist on current host. Skipping $service configuration.");
    return(1);
  }

  # Update named configuration file with configuration embedded in the configuration
  # or with the reference file, if one of them has been specified

  my $server_changes;
  my $named_root_dir = $self->getNamedRootDir();
  return unless defined($named_root_dir);

  if ( $named_config->{serverConfig} ) {

      $self->info("Checking $service configuration (".$named_root_dir.NAMED_CONFIG_FILE.")...");
      $server_changes = LC::Check::file($named_root_dir.NAMED_CONFIG_FILE,
                                        contents    => encode_utf8($named_config->{serverConfig}),
                                        backup      => '.ncm-named',
                                        owner       => 0,
                                        mode        => 0644
                                       );
      unless (defined($server_changes)) {
        $self->error('error updating '.$named_root_dir.NAMED_CONFIG_FILE);
        return;
      }
  } elsif ( $named_config->{configfile} ) {
      $self->info("Checking $service configuration (".$named_root_dir.NAMED_CONFIG_FILE.") using ".$named_config->{configfile}."...");
      $server_changes = LC::Check::file($named_root_dir.NAMED_CONFIG_FILE,
                                        source      => $named_config->{configfile},
                                        backup      => '.ncm-named',
                                        owner       => 0,
                                        mode        => 0644
                                       );
      unless (defined($server_changes)) {
        $self->error('error updating '.$named_root_dir.NAMED_CONFIG_FILE.' from reference file '.$named_config->{configfile});
        return;
      }
  }

  # Enable named service

  my $reboot_state;
  if ( $server_enabled ) {
    $self->info("Enabling service $service...");
    $reboot_state = "on";
  } else {
    $self->info("Disabling service $service...");
    $reboot_state = "off";
  }
  $cmd = CAF::Process->new(["/sbin/chkconfig", "--level", "345", $service, $reboot_state], log => $self);
  $cmd->output();      # Also execute the command
  if ( $? ) {
    $self->error("Error defining service $service state for next reboot.");
  }

  # Start named if enabled and not yet started.
  # Stop named if running but disabled.
  # Restart after a configuration change if enabled and started.
  # Do nothing if the 'start' property is not defined.

  $self->debug(1,"Checking if service $service is started...");
  my $named_started = 1;
  $cmd = CAF::Process->new(["/sbin/service", $service, "status"], log => $self);
  $cmd->output();      # Also execute the command
  if ( $? ) {
    $self->debug(1,"Service $service not running.");
    $named_started = 0;
  } else {
    $self->debug(1,"Service $service is running.");
  }

  my $action;
  if ( defined($server_enabled) ) {
    if ( $server_enabled ) {
      if ( ! $named_started ) {
        $action = 'start';
      } elsif ( $server_changes ) {
        $action = 'restart';
      }
    } else {
      if ( $named_started ) {
        $action = 'stop';
      };
    }
  }

  if ( $action ) {
    $self->info("Doing a $action of service $service...");
    $cmd = CAF::Process->new(["/sbin/service", $service, $action], log => $self);
    my $cmd_output = $cmd->output();      # Also execute the command
    if ( $? ) {
      $self->debug(1,"Failed to update service $service state.\nError message: $cmd_output");
      $named_started = 0;
    }
  } else {
    $self->debug(1,"No need to start/stop/restart service $service");
  }


  return;
}


##########################################################################
# Retrieve named root dir (used when named is chrooted) from sysconfig file
# and check that it is a valid path, as defined by ROOTDIR variable.
# If the sysconfig file is not present or the ROOTDIR variable is not
# explicitely defined, assume that named is not run chrooted and return an
# empty string.
#
# Return value : named root dir if defined or the empty string
#
sub getNamedRootDir {
###########################################################################

  my $self = shift;
  my $named_root_dir = "";

  my $fh = CAF::FileEditor->new(NAMED_SYSCONFIG, log => $self);
  unless ( defined($fh) ) {
      return "";
  }
  $fh->cancel();

  while ( my $line = <$fh> ) {
      if ($line =~ /^\s*ROOTDIR\s*=/) {
          $line =~ s/^\s*ROOTDIR\s*=//g;
          chomp($line);
          $named_root_dir = $line;
      }
  }

  $fh->close();

  if ( !$named_root_dir ) {
      $self->debug(1,"No named root directory definition found in ".NAMED_SYSCONFIG.", assume named is not chrooted");
  } elsif  ( $named_root_dir =~ m{^['"]?(/[-\w\./]+)['"]?$}) {
      $named_root_dir = $1;
      $self->debug(1,"named root dir successfully retrieved from ".NAMED_SYSCONFIG.": $named_root_dir");
  } else {
      $self->error("Weird named root dir: $named_root_dir");
  }

  return $named_root_dir;
}

1; #required for Perl modules
