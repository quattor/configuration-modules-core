################################################################################
# This is 'cups.pm', a ncm-cups's file
################################################################################
#
# VERSION:    1.1.3, 16/09/08 16:37
# AUTHOR:     Michel Jouvin <jouvin@lal.in2p3.fr>
# MAINTAINER: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################
#
# NCM cups component
#
# CUPS configuration component
#
# This component allow to configure and manage configuration files for CUPS,
# including restart of daemons if needed.
#
# It supports virtually all the configuration options supported by CUPS in
# the client.conf and cupsd.conf configuration files and for printers.
# But actually not all the options have been declared yet to the component...!!!
#
# If you need support for an option not yet supported, this should be very easy.
# Looks at comments below, before the %supported_options hash.
# Normally, it should be enough to add the new option in this hash and in
# the declaration template (components_cups_options),
# pro_declaration_component_cups.tpl.
#
# For printer related options, look at comments below, before %printer_options_supported
#
# Verbose output can be produced to help trouble shooting problems
# by specifying option --debug 1 to ncm-ncd
#
################################################################################

package NCM::Component::cups;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element;

use LC::File qw(file_contents);
use LC::Check;

# Use output function to discard command-line output. It might be
# nicer if we opened /dev/null and passed that handle to execute or
# run. We will use $? to check the exit status of our commands.
use LC::Process qw (execute output);

use Net::Domain qw(hostname hostfqdn hostdomain);

local(*DTA);

# Define paths for convenience.
my $base = "/software/components/cups";

my $cupsd_startup_script = "/etc/rc.d/init.d/cups";

# Support for CUPS options has been designed to be flexible and allow easy
# addition of new options.
# It is provided by the 3 next hashes :
#	- %supported_options : list the supported options and the roles that use them
#	- %config_files : describe the configuration file corresponding to each role
#	- %services : list the daemons used by each role
#
# Normally adding support for a new option requires only to add it in the
# %supported_options hash, with the format described below (don't forget to
# add it to the declaration template too).

# For each supported option, list the roles affected by the option
# This can be a list of roles separated by ','
my %supported_options = ("autopurgejobs" => "server",
			 "classification" => "server",
			 "classifyoverride" => "server",
			 "datadir" => "server",
			 "defaultcharset" => "server",
			 "encryption" => "client",
			 "errorlog" => "server",
			 "loglevel" => "server",
			 "maxcopies" => "server",
			 "maxlogsize" => "server",
			 "preservejobhistory" => "server",
			 "preservejobfiles" => "server",
			 "printcap" => "server",
			 "serveradmin" => "server",
			 "servername" => "client,server",
			);
my %config_files = ("server" => "/etc/cups/cupsd.conf",
		   "client" => "/etc/cups/client.conf",
		   );
my %services = ("server" => "cups");


my %config_rules = ("server" => {},
		    "client" => {},
		   );


# Printer options supported : value is passed literaly to lpadmin.
# For each option, hash key is the name of the template property associated
# with the option and hash value is the option to pass to lpadmin.
# Printer uri is not listed here and processed specifically.

my %printer_options_supported = ("class" => "-c",
				 "description" => "-D",
				 "location" => "-L",
				 "model" => "-m",
				 "ppd" => "-P",
				 "uri" => "-v",
				);

my $config_bck_ext = ".old";		# Replaced version extension
#my $config_prod_ext = ".new";		# For testing purpose only
my $config_prod_ext = "";		# Must be empty except for testing purpose

my @enable_actions = ("disable", "enable");	# For debugging messages

my $accept_cmd = "/usr/sbin/accept";
my $disable_cmd = "/usr/bin/disable";
my $enable_cmd = "/usr/bin/enable";
my $lpadmin_cmd = "/usr/sbin/lpadmin";

my $true = "true";
my $false = "false";

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  my $this_host_name = hostname();
  my $this_host_domain = hostdomain();
  my $this_host_full = join ".", $this_host_name, $this_host_domain;

  # Check if named server must be enabled

  my $server_enabled = undef;
  my $nodetype_option = "$base/nodetype";
  if ( $config->elementExists($nodetype_option) ) {
    if ( $config->getElement($nodetype_option)->getValue() =~ /server/i ) {
      $server_enabled = 1;
    } else {
      $server_enabled = 0;
    }
  }


  # Retrieve and process CUPS options
  my $cups_options_path = "$base/options";
  if ($config->elementExists($cups_options_path)) {
    my $cups_options = $config->getElement($cups_options_path);
    while ($cups_options->hasNextElement()) {
      my $cups_option = $cups_options->getNextElement();
      my $option_name = $cups_option->getName();
      $self->debug(1,"Processing cups option '$option_name'");
      if ( ! exists($supported_options{$option_name}) ) {
	$self->warn("Internal error : unsupported option '$option_name'");
	next;	# Log a warning but continue processing
      }

      # Get option value and and if option is 'servername', do some specific
      # processing to determine if this machine need to run the server
      my $option_value = $cups_option->getValue();
      if ( $option_name eq "servername" ) {
	(my $host, my $domain) = split /\./, $option_value, 2;
	unless ( $domain || ($host eq "localhost") ) {
	  $self->warn("Server name not fully qualified. Adding domain $domain");
	  $option_value = $this_host_full;
	}
	# If server=localhost, better to use real name in configuration file
	if ( $option_value eq "localhost" ) {
	  $option_value = $this_host_full;
	}
	if ( ! defined($server_enabled) ) {
	  if ( $option_value eq $this_host_full ) {
	    $server_enabled = 1;
	  } else {
	    $server_enabled = 0;
	  }
	} else {
	  if ( $option_value ne $this_host_full ) {
	    $self->warn("Current host defined as a CUPS server but client configured to use $host");
	  }
	}
      }

      # $option_roles is a list of roles separated by ','
      # If $option_value is empty, treat as a request to comment out the line
      # if present (to use cups default).
      # If the $option_value is made only of spaces, it is interpreted as a
      # null value
      my $option_roles = $supported_options{$option_name};
      my @option_roles = split /\s*,\s*/, $option_roles;
      for my $option_role (@option_roles) {
	if ( $option_value ) {
	  if ( $option_value =~ /^\s+$/ ) {
	    $option_value = '';
	  }
	  # If CUPS server is current host, use 127.0.0.1 for the client
	  if ( ($option_role eq "client") &&
	       ($option_name eq "servername") &&
	       ($option_value eq $this_host_full) ) {
	    $self->addConfigEntry($option_role,$option_name,"127.0.0.1");
	  } else {
	    $self->addConfigEntry($option_role,$option_name,$option_value);
	  }
	} else {
	  $self->removeConfigEntry($option_role,$option_name);
	}
      }
    }
  } else {
    $self->debug(1,"No option defined");
  }


  # If $server_enabled still undefined, that means that servername option has
  # not been specified. Thus the current host need to be a server (default
  # CUPS configuration).
  unless (defined($server_enabled)) {
      $server_enabled = 1;
  }


  my %config_changes;
  for my $cups_role (keys(%config_files)) {
    $config_changes{$cups_role} = $self->updateConfigFile($cups_role);
    if ( $config_changes{$cups_role} < 0 ) {
      $self->error("Error updating configuration file for role ($config_changes{$cups_role})");
      return 1;
    }
  }

  # Start or stop cupsd according to state property

  if ( -e $cupsd_startup_script ) {
    my $reboot_state = "off";
    if ($server_enabled) {
      $reboot_state = "on";
    }

    # Make sure, that cupsd will be started/stopped on boot (acccording to 'start')
    output ("/sbin/chkconfig", $services{server}, $reboot_state);
    if ($?) {
      $self->error("command \"/sbin/chkconfig $services{server} $reboot_state\" failed with status: $?");
      return 1;
    }

  } else {
    if ( $server_enabled ) {
      $self->error("$services{server} startup script doesn't exist");
      return 0;
    } else {
      $self->debug(1,"$services{server} startup script doesn't exist");
    }
  }

  if ( $server_enabled ) {
    # Actual action is determined by serviceControl() after getting current status
    my $action;
    if ( $config_changes{server} > 0 ) {
      $action = "reload";
    } else {
      $action = "start";
    }

    $self->serviceControl($services{server},$action);

    # Retrieve and process printers options. Check for conflicts and multiple
    # definition.
    # Check that the default printer, if defined, exists

    my $default_printer = undef;
    my $cups_defprinter_path = "$base/defaultprinter";
    if ($config->elementExists($cups_defprinter_path)) {
      $default_printer = $config->getElement($cups_defprinter_path)->getValue();
      $self->debug(1,"Default printer defined in the configuration : $default_printer");
    }

    my %printers;
    my $cups_printers_path = "$base/printers";
    if ($config->elementExists($cups_printers_path)) {
      my $cups_printers = $config->getElement($cups_printers_path);
      while ( $cups_printers->hasNextElement() ) {
	my $printer_path = $cups_printers->getNextElement()->getPath()->toString();
	my %printer_options;
	my $printer_name = $config->getElement("$printer_path/name")->getValue();

	my $printer_previous_definition;
	if ( exists($printers{$printer_name}) ) {
	  $self->debug(1,"Printer $printer_name already defined. Checking for new options...");
	  $printer_previous_definition = $printers{$printer_name};
	}

	if ( $config->elementExists("$printer_path/delete") && $config->getElement("$printer_path/delete")->getValue() ) {
	  if ( ! defined($printer_previous_definition) ||
	       ! $printer_previous_definition->{delete} ) {
	    $self->debug(1,"Printer $printer_name marked for deletion");
	    if ( ! defined($printer_previous_definition) ) {
	      $printer_options{delete} = 1;
	      $printers{$printer_name} = \%printer_options;
	    } else {
	      $printer_previous_definition->{delete} = 1;
	    }
	  }

	} else {
	  if ( ! $config->elementExists("$printer_path/uri") ) {
	    unless ( $config->elementExists("$printer_path/protocol") ) {
	      $self->error("Neither printer URI nor printer protocol defined");
	    }
	    unless ( $config->elementExists("$printer_path/server") ) {
	      $self->error("Neither printer URI nor printer server defined");
	    }
	    my $printer_uri = lc($config->getElement("$printer_path/protocol")->getValue()) . "://" . $config->getElement("$printer_path/server")->getValue() . "/";
	    if ( $config->elementExists("$printer_path/printer") ) {
	      $printer_uri .= $config->getElement("$printer_path/printer")->getValue();
	    } else {
	      $printer_uri .= $printer_name;
	    }
	    $printer_options{options} .= "-v\t$printer_uri\t";
	  }

	  $printer_options{enable} = 1;		# Assume enable by default
	  if ( $config->elementExists("$printer_path/enable") && ! $config->getElement("$printer_path/enable")->getValue() ) {
	    $printer_options{enable} = 0;
	  }

	  for my $option (keys(%printer_options_supported)) {
	    if ( $config->elementExists("$printer_path/$option") ) {
	      $printer_options{options} .= $printer_options_supported{$option}.
		"\t".$config->getElement("$printer_path/$option")->getValue()."\t";
	    }
	  }

	  if ( ! defined($printer_previous_definition) ) {
	    $self->debug(1,"Printer $printer_name added to printers list");
	    $printers{$printer_name} = \%printer_options;
	  } else {
	    if ( $printer_previous_definition->{delete} ) {
	      $self->debug(1,"Printer $printer_name already marked for deletion. New definition ignored");
	    } else {
	      if ( $printer_options{options} ne $printer_previous_definition->{options} ) {
		$self->warn("Printer $printer_name already defined with different options. Ignoring redefinition");
	      } else {
		$self->debug(1,"Printer $printer_name already redefined with same options. Ignoring duplicate");
	      }
	      if ( $printer_options{enable} && ! $printer_previous_definition->{enable} ) {
	      $self->debug(1,"Enabling already defined printer $printer_name");
	      $printer_previous_definition->{enable} = 1;
	      }
	    }
	  }
	}
      }

      for my $printer (keys(%printers)) {
	if ( $printers{$printer}->{delete} ) {
	  if ( $self->printerDelete($printer) ) {
	    $self->warn("Error deleting printer $printer");
	  } else {
	    $self->OK("Printer $printer deleted");
	  }
	} else {
	  if ( $self->printerAdd($printer,$printers{$printer}->{options}) ) {
	    $self->warn("Error adding printer $printer");
	    next;
	  } else {
	    $self->OK("Printer $printer added");
	  }

	  if ( $self->printerEnable($printer,$printers{$printer}->{enable}) ) {
	    $self->warn("Failed to ".$enable_actions[$printers{$printer}->{enable}]." printer $printer");
	  }
	}
      }

      if ( $default_printer &&
	   exists($printers{$default_printer}) &&
	   ! $printers{$default_printer}->{delete} ) {
	if ($self->printerDefault($default_printer)) {
	  $self->warn("Error defining printer $default_printer as the default printer");
	} else {
	  $self->OK("Default printer defined to $default_printer");
	}
      } else {
	$self->warn("Default printer $default_printer doesn't exist. Ignoring");
      }
    }

  }

  return 0;	# Success
}


# Add a printer or modify its configuration.
#
# Arguments :
#	printer : default printer name
#	options : printer options
#
# Returned value :
#	0 : success
#	1 : failure

sub printerAdd() {
  my $function_name = "printerAdd";
  my $self = shift;
  my $printer = shift;
  unless ( $printer ) {
    $self->error("$function_name : 'printer' argument missing");
    return 1;
  }

  my $options = shift;
  unless ( $options ) {
    $self->error("$function_name : 'options' argument missing");
    return 1;
  }
  $self->debug(1,"$function_name : defining printer '$printer' (options='$options'");
  execute ([$lpadmin_cmd, "-p", $printer, split('\t',$options) ]);

  return $?
}


# Delete a printer. If the printer doesn't exist, return success.
#
# Arguments :
#	printer : default printer name
#
# Returned value :
#	0 : success
#	1 : failure

sub printerDelete() {
  my $function_name = "printerDelete";
  my $self = shift;

  my $printer = shift;
  unless ( $printer ) {
    $self->error("$function_name : 'printer' argument missing");
    return 1;
  }

  $self->debug(1,"$function_name : deleting printer '$printer'");
  my $status = 0;	# Assume success
  my $error_msg = output ($lpadmin_cmd, "-x", $printer);
  if ( $error_msg && ($error_msg !~ /client-error-not-found/) ){
    $status = 1;
  }

  return $status
}


# Enable+Accept/Disable a printer.
#
# Arguments :
#	printer : default printer name
#	enable flag : if true, enable, else disable (optional, D: enable)
#
# Returned value :
#	0 : success
#	1 : failure

sub printerEnable() {
  my $function_name = "printerEnable";
  my $self = shift;

  my $printer = shift;
  unless ( $printer ) {
    $self->error("$function_name : 'printer' argument missing");
    return 1;
  }

  my $enable = shift;
  if ( ! defined($enable) ) {
    $enable = 1;	# Default is to enable
  }

  my $cmd;
  if ( $enable ) {
    output ($enable_cmd, $printer);
    output ($accept_cmd, $printer);
    $self->debug(1,"$function_name : enabling printer '$printer'");
  } else {
    output ($disable_cmd, $printer);
    $self->debug(1,"$function_name : disabling printer '$printer'");
  }

  return $?
}


# Define a printer as the default printer.
#
# Arguments :
#	printer : default printer name
#
# Returned value :
#	0 : success
#	1 : failure

sub printerDefault() {
  my $function_name = "printerDefault";
  my $self = shift;

  my $printer = shift;
  unless ( $printer ) {
    $self->error("$function_name : 'printer' argument missing");
    return 1;
  }

  $self->debug(1,"$function_name : defining '$printer' as default printer");
  output ($lpadmin_cmd, '-d', $printer);
  return $?
}


# Add a configuration line to the role configuration.
# This line is added as a hash element whose key is the keyword and value
# the keyword value.
#
# Arguments :
#	Role type : client or server
#	Keyword : configuration line keyword
#	Value : keyword value (can be empty but must be present)
#
# Return value :
#       0 : success
#	> 0 : failure

sub addConfigEntry() {
  my $function_name = "addConfigEntry";
  my $self = shift;

  my $role = shift;
  unless ( $role ) {
    $self->error("$function_name : 'role' argument missing");
    return 1;
  }

  my $keyword = shift;
  unless ( $keyword ) {
    $self->error("$function_name : 'keyword' argument missing");
    return 1;
  }

  my $value = shift;
  unless ( defined($value) ) {
    $self->error("$function_name : 'value' argument missing");
    return 1;
  }

  $self->debug(1,"$function_name : adding keyword=$keyword, value=$value for role $role");
  $config_rules{$role}->{$keyword} = $value;

  return 0;
}

# Mark a specific configuration line to be commented out
# This line is added as a hash element whose key is the keyword and value
# is undef
#
# Arguments :
#	Role type : client or server
#	Keyword : configuration line keyword
#
# Return value :
#       0 : success
#	> 0 : failure

sub removeConfigEntry() {
  my $function_name = "removeConfigEntry";
  my $self = shift;

  my $role = shift;
  unless ( $role ) {
    $self->error("$function_name : 'role' argument missing");
    return 1;
  }

  my $keyword = shift;
  unless ( $keyword ) {
    $self->error("$function_name : 'keyword' argument missing");
    return 1;
  }

  $self->debug(1,"$function_name : removing keyword=$keyword");
  $config_rules{$role}->{$keyword} = undef;

  return 0;
}


# Return config file entries for one specific role (server, client)...
#
# Arguments :
#	Role type : client or server
#
# Return value :
#	Hash containing configuration entries or undef

sub getConfigEntries() {
  my $function_name = "getConfigEntries";
  my $self = shift;

  my $role = shift;
  unless ( $role ) {
    $self->error("$function_name : 'role' argument missing");
    return 1;
  }

  $self->debug(2,"$function_name : config_rules = $config_rules{$role}");
  return $config_rules{$role};

}


# Start, stop or reload a service.
# The actual action performed on the service is determined
# according to the current state of the service and the action requested.
#
# Argument :
#	Service : service name (must match a service in /etc/rc.d/init.d)
#	Action : action to perform on the service
#
# Return value :
#       0 : success
#	> 0 : failure

sub serviceControl () {
  my $function_name = "serviceControl";
  my $self = shift;

  my $service = shift;
  unless ( $service ) {
    $self->error("$function_name : 'service' argument missing");
    return 1;
  }

  my $action = shift;
  unless ( $action ) {
    $self->error("$function_name : 'action' argument missing");
    return 1;
  }

  $self->debug(1,"$function_name : '$action' action requested for service $service");

  # Check current service state (return=0 means service is running)
  my $cur_state = "stopped";
  output ("service", "$service", "status");
  unless ($?) {
    $cur_state = "started";
  }


  # Determine real action to do based on action requested and current state

  my $real_action;
  if ( $action eq "start" ) {
    if ( $cur_state eq "stopped" ) {
      $real_action = "start";
    } else {
      $self->debug(1,"$function_name : service $service already running. Nothing done.");
      return;
    }
  } elsif ( $action eq "stop" ) {
    if ( $cur_state eq "stopped" ) {
      $self->debug(1,"$function_name : service $service already stopped. Nothing done.");
      return;
    } else {
      $real_action = "stop";
    }
  } elsif ( $action eq "reload" ) {
    if ( $cur_state eq "stopped" ) {
      $real_action = "start";
    } else {
      $real_action = "reload";
    }
  } else {
    $self->error("$function_name : internal error : unsupported action ($action)");
    return 1;
  }

  # Do action

  $self->info("Executing a '$real_action' of service $service");
  output ("service", $service, $real_action);
  if ($?) {
    $self->error("\tFailed to $real_action service $service");
    return 1;
  }

  return 0;
}


# This function and all functions related to editing rules management are
# derived from (more complex) equivalent routines in ncm-dpmlfc. Basic structure
# has been kept to allow easy further extensions, if needed.
#

# Create list of lines matching a specific rule in a rules list
# This list in array, with array index corresponding to the order in
# the rules list.
# Each list element is an array, with one element for each line matching the
# corresponding rule. Each element describing a line is a hash describing
# the line number (LINENUM) and the line format (LINEFORMAT).
#
# Created list is returned.
#
# Arguments :
#        config_rules : rules list
#
# Return value :
#       list pointer or undef

sub createRulesMatchesList () {
  my $function_name = "createRulesMatchesList";
  my $self = shift;

  my $config_rules = shift;
  unless ( $config_rules ) {
    $self->error("$function_name : 'config_rules' argument missing");
    return 0;
  }

  $self->{RULESMATCHES} = [];

  my $rule_id = 0;
  for my $keyword (keys(%{$config_rules})) {
    ${$self->{RULESMATCHES}}[$rule_id] = [];
    $rule_id++;
  }

  return $self->{RULESMATCHES};
}


# Function returning reference to list of lines matching a configuration rule
#
# Arguments :
#        rule_id : rule indentifier for which to retrieve matches
#
# Return value :
#       list pointer or undef

sub getRuleMatches () {
  my $function_name = "getRuleMatches";
  my $self = shift;

  my $rule_id = shift;
  unless ( defined($rule_id) ) {
    $self->error("$function_name : 'rule_id' argument missing");
    return 0;
  }

  return ${$self->{RULESMATCHES}}[$rule_id];
}


# Function to add a line in RulesMatchingList
#
# Arguments :
#        rule_id : rule indentifier for which to retrieve matches
#        line_num : matching line number (in the config file)
#
# Return value :
#       0 : success
#	> 0 : failure

sub addInRulesMatchesList () {
  my $function_name = "addInRulesMatchesList";
  my $self = shift;

  my $rule_id = shift;
  unless ( defined($rule_id) ) {
    $self->error("$function_name : 'rule_id' argument missing");
    return 1;
  }
  my $line_num = shift;
  unless ( defined($line_num) ) {
    $self->error("$function_name : 'line_num' argument missing");
    return 1;
  }

  $self->debug(1,"$function_name : adding line $line_num to rule $rule_id list");
  my $list = $self->getRuleMatches($rule_id);
  my %line;
  $line{LINENUM} = $line_num;
  push @{$list}, \%line;

}


# Function returning line number corresponding to one element in RulesMatchingList or 'undef' if there is no more element
#
# Arguments :
#        rule_id : rule indentifier for which to retrieve matches
#        entry_num : rule match number
#
# Return value :
#	0 : failure
#	>0 : line number

sub getRulesMatchesLineNum () {
  my $function_name = "getRulesMatchesLineNum";
  my $self = shift;

  my $rule_id = shift;
  unless ( defined($rule_id) ) {
    $self->error("$function_name : 'rule_id' argument missing");
    return 0;
  }
  my $entry_num = shift;
  unless ( defined($entry_num) ) {
    $self->error("$function_name : 'entry_num' argument missing");
    return 0;
  }

  my $list = $self->getRuleMatches($rule_id);
  my $entry =  ${$list}[$entry_num];

  return ${$entry}{LINENUM};
}


# Build a new configuration file content, using template contents if any and
# applying configuration rules to transform the template.
#
# Arguments :
#       config_rules : config rules corresponding to the file to build
#       template_contents (optional) : config file template to be edit with rules.
#                                      If not present build a new file content.
#
# Return value :
#       new contents or 0 in case of error

sub buildConfigContents () {
  my $function_name = "buildConfigContents";
  my $self = shift;

  my $config_rules = shift;
  unless ( $config_rules ) {
    $self->error("$function_name : 'config_rules' argument missing");
    return 0;
  }
  my $template_contents = shift;

  my @newcontents;
  my @rule_lines;
  my $rule_id = 0;

  # $file_line_offset is the number to add to @newcontents index (starting at 0)
  # to get the file line number (starting at 1)
  # Used in debugging messages to ease line identification
  my $file_line_offset = 1;

  # Intialize this array of array (each array element is an array containing
  # each line where the keyword is present)
  $self->createRulesMatchesList($config_rules);


  my $intro = "# This file is managed by Quattor - DO NOT EDIT lines generated by Quattor";
  if ( $template_contents ) {
    my $line_num = 0;
    my @previous_contents = split /\n/, $template_contents;

    if ($previous_contents[0] ne $intro) {
      $newcontents[0] = "$intro\n#" ;
      my @intro_lines = split /\cj/, $newcontents[0];	# /\cj/ matches embedded \n
      # $file_line_offset need to take into accout intro line added
      $file_line_offset = @intro_lines;
      $line_num++;
    }

    # In a template file, keyword must appear at the beginning of  a line.
    # Line may be commented out and keyword may be followed by a value or
    # comment.
    #
    # Pattern matching is as restrictive as possible to avoid false positive.

    for my $line (@previous_contents) {
      $rule_id = 0;
      for my $keyword (keys(%{$config_rules})) {
	if ( $line =~ /^\s*\#*\s*(?i:$keyword)(?:\s+[[:alnum:]\/\.-_,\'\"\#]+)*$/ ) {
	  $self->addInRulesMatchesList($rule_id,$line_num);
	}
	$rule_id++;
      }
      push @newcontents, $line;
      $line_num++;
    }
  } else {
    $newcontents[0] = "$intro\n#" ;
    my @intro_lines = split /\cj/, $newcontents[0];	# /\cj/ matches embedded \n
    # $file_line_offset need to take into accout intro line added
    $file_line_offset = @intro_lines;
  }

  # Each rule is a string that is the value of the keyword
  # An empty rule is valid and means that only the keyword part must be
  # written. A rule with value 'undef' means that this keyword if present
  # must be commented out with the original line kept.
  # Matching line is unconditionnally rewritten in memory but the file will
  # be updated only if its contents has changed. Thus rewritting the same line
  # here doesn't cause a file update.

  $rule_id = 0;
  for my $keyword (keys(%{$config_rules})) {
    my $config_value = $config_rules->{$keyword};

    # Build configuration line if config_value is defined
    my $comment = "# Added by Quattor";
    my $config_line;
    if ( defined($config_value) ) {
      $config_line = ucfirst($keyword);
      if ( $config_value ) {
	$config_line .= "\t$config_value";
      }
    }

    my $entry_num = 0;
    if ( $self->getRulesMatchesLineNum($rule_id,$entry_num) ) {
      while ( my $line = $self->getRulesMatchesLineNum($rule_id,$entry_num) ) {
	my $file_line = $line + $file_line_offset;
	my $line_modified = 0;
	if ( defined($config_value) ) {
	  if ( $newcontents[$line] ne $config_line) {
	    $newcontents[$line] = $config_line;
	    $self->debug(1,"$function_name : file line $file_line replaced");
	    $line_modified = 1;
	  }
	  if ( ($line == 0) || ($newcontents[$line-1] ne $comment) ) {
	    $self->debug(1,"$function_name : file line $file_line : comment added");
	    $newcontents[$line] = "$comment\n$newcontents[$line]";
	    $file_line_offset++;
	    $line_modified = 1;
	  }
	} else {
	  if ( $newcontents[$line] !~ /^\s*\#/ ) {
	    $self->debug(1,"$function_name : file line $file_line commented out");
	    $newcontents[$line] = "#$newcontents[$line]";
	    $line_modified = 1;
	  }
	  if ( ($line == 0) || ($newcontents[$line-1] ne $comment) ) {
	    $self->debug(1,"$function_name : file line $file_line : comment added");
	    $newcontents[$line] = "$comment\n$newcontents[$line]";
	    $file_line_offset++;
	    $line_modified = 1;
	  }
	}
	unless ( $line_modified ) {
	  $self->debug(1,"$function_name : file line $file_line unmodified");
	}
	$entry_num++;
      }
    } else {
      # In a new file, don't add commented out lines
      if ( defined($config_value) ) {
	push @newcontents, $config_line;
	$self->debug(1,"$function_name : configuration line added");
      } else {
	$self->debug(1,"$function_name : commented out line ignored (keyword=$keyword)");
      }
    }

    $rule_id++;
  }

  my $newcontents = join "\n",@newcontents;
  $newcontents .= "\n";		# Add LF after last line
  return $newcontents;
}


# Create a new configuration file, using a template if any available and
# applying configuration rules to transform the template.
#
# Arguments :
#       role : role a configuration file must be build for
#
# Returned value :
#	0 : success, no update
#	>0 : success, number of changes
#	<0 : error
sub updateConfigFile () {
  my $function_name = "updateConfigFile";
  my $self = shift;

  my $role = shift;
  unless ( $role ) {
    $self->error("$function_name : 'role' argument missing");
    return -1;
  }

  $self->debug(1,"$function_name : Building configuration file for $role role ");
  unless ($config_rules{$role}) {
    $self->debug(1,"$function_name : no rule for role $role, nothing done");
    return -1;
  }

  my $template_contents;
  my $template_file = $config_files{$role};
  if ( -e $template_file ) {
    $self->debug(1,"$function_name : template file $template_file found, reading it");
    $template_contents = file_contents($template_file);
    $self->debug(3,"$function_name : template contents :\n$template_contents");
  }

  my $config_contents=$self->buildConfigContents($config_rules{$role}, $template_contents);
  $self->debug(3,"$function_name : Configuration file new contents :\n$config_contents");

  # Update configuration file if content has changed
  # Nothing happens if config_contents is identical to current file content
  my $changes = LC::Check::file($config_files{$role}.$config_prod_ext,
				backup => $config_bck_ext,
				contents => $config_contents
			       );
  unless (defined($changes)) {
    $self->error("error creating $role role configuration file ($config_files{$role}");
    return -1;
  }

  return $changes;

}


1; #required for Perl modules
