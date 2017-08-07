#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

use EDG::WP4::CCM::Path 16.8.0 qw(unescape);

use CAF::FileEditor;
use CAF::FileWriter;
use CAF::Process;

use Encode qw(encode_utf8);

use Net::Domain qw(hostname hostfqdn hostdomain);

# Define paths for convenience.
my $base = "/software/components/mysql";

# Define some commands explicitly
my $chkconfig = "/sbin/chkconfig";
my $servicecmd = "/sbin/service";

my $true = "true";
my $false = "false";

# Global context
my $this_host_name;
my $this_host_domain;
my $this_host_full;
my $servers;
my $databases;


sub Configure
{

  my ($self, $config)=@_;

  my $changes;
  my $status;

  # Retrieve local host name
  $this_host_name = hostname();
  $this_host_domain = hostdomain();
  $this_host_full = join ".", $this_host_name, $this_host_domain;

  # Retrieve component configuration
  my $confighash = $config->getElement($base)->getTree();
  $databases = $confighash->{databases};
  $servers = $confighash->{servers};
  my $serviceName = $confighash->{serviceName};

  # Loop over all servers (even if no db in the configuration uses them)

  for my $server_name (sort(keys(%{$servers}))) {
      my $server = $servers->{$server_name};
      if ( !defined($server->{host}) ) {
          $server->{host} = $server_name;
      }

      # If MySQL server is local node, check that MySQL is already started and configure server
      # parameters.

      if ( ($server->{host} eq $this_host_full) || ($server->{host} eq 'localhost') ) {
          my $cmd;
          $self->info("Checking if MySQL service ($serviceName) is enabled and started...");
          $cmd = CAF::Process->new([$chkconfig, $serviceName, "on"], log => $self);
          $cmd->output();      # Also execute the command
          if ( $? ) {
              $self->error("Error enabling MySQL server on local node");
              return(1);
          }

          $cmd = CAF::Process->new([$servicecmd, $serviceName, "status"], log => $self);
          $cmd->output();      # Also execute the command
          if ( $? ) {
              $self->info("Starting MySQL server...");
              $cmd = CAF::Process->new([$servicecmd, $serviceName, "start"], log => $self);
              my $cmd_output = $cmd->output();      # Also execute the command
              $status = $?;
              if ( $? ) {
                  $self->error("Error starting MySQL server on local node : $status\nCommand output: $cmd_output");
                  return(1);
              }
          } else {
              $self->debug(1,"MySQL server already started");
          }

          # Configure server parameters
          # Use double braces to be able to exit this block from anywhere
          # still continuing to execute other sections.
          # Index for iterating over lines is zero-based, don't forget to add one when printing version
          # numbers
          if ( $server->{options} ) {
              my $mysql_conf_file = '/etc/my.cnf';
              $self->debug(1,"Setting MySQL server parameters on ".$server->{host}." ($mysql_conf_file)");
              my %opt;
              $opt{backup} = '.old';
              $opt{log} = $self;
              my $fh = CAF::FileEditor->new($mysql_conf_file,%opt);
              unless ( defined($fh) ) {
                  $self->warn("Error opening current MySQL server configuration file ($mysql_conf_file)");
                  last;       # Give up setting of server parameters
              };
              $fh->seek_begin();
              my @mysql_conf = <$fh>;
              $self->debug(2,"Number of lines in current $mysql_conf_file : ".@mysql_conf);

              my $server_section_found = 0;
              my %indexes;
              my $i = 0;
              my $blank_lines = 0;

              # Iterate over config to locate [mysqld] section if any.
              # [mysqld] section is not necessarily the first one.
              for ($i=0; $i<@mysql_conf; $i++) {
                  chomp $mysql_conf[$i];
                  $self->debug(2,"Processing line ".($i+1).": >>>$mysql_conf[$i]<<<");
                  # New section found
                  if ( $mysql_conf[$i] =~ /^\s*\[\s*([\w.\-]+)\s*\]/ ) {
                      my $section_name = $1;
                      # Section [mysqld] found
                      if ( $1 eq 'mysqld' ) {
                          if ( $server_section_found ) {
                              $self->warn('Duplicated [mysqld] section was found at line'.($i+1));
                          } else {
                              $self->debug(1,"[mysqld] start line: ".($i+1));
                              $server_section_found = 1;
                              $blank_lines = 0;
                          }
                      } else {
                          $self->debug(2,"New section found at line ".($i+1).": $section_name");
                          # If [mysqld] has already been processed, there is no point to iterate more...
                          if ( $server_section_found ) {
                              last;
                          }
                      }
                      next;
                  }
                  # Process [mysqld] section looking for parameters to modify, until the end of the section
                  # (end of configuration or new section)
                  if ( $server_section_found ) {
                      if ( $mysql_conf[$i] =~ /^\s*$/ ) {
                          $blank_lines += 1;
                      } else {
                          if ( $blank_lines > 0 ) {
                              $self->warn('Unexpected blank lines found from line '.($i-$blank_lines+1).' to '.$i);
                              $blank_lines = 0;
                          }
                          for my $option (keys(%{$server->{options}})) {
                              if ( $mysql_conf[$i] =~ /^\s*$option\s*=/ ) {
                                  $self->debug(2,"Option $option found at line ".($i+1));
                                  $indexes{$option} = $i;
                              }
                          }
                      }
                  }
              }

              # Go back to find last non blank line (last line of [mysqld] section if it exists else last line of the config file)
              # and set pointer to next line after it.
              $self->debug(2,"Line number after configuration file parsing. ".($i+1).". Going back to find first non blank line...");
              my $mysqld_conf_next;
              for ($mysqld_conf_next=$i-1; $mysqld_conf_next>=0; $mysqld_conf_next--) {
                  if ( $mysql_conf[$mysqld_conf_next] !~ /^\s*$/ ) {
                      last;
                  }
              }
              $mysqld_conf_next++;
              $self->debug(1,"Next line number after [mysqld] section : ".($mysqld_conf_next+1));

              # Copy the rest of the original configuration in a temporary array
              my @conf_end;
              for (my $i=$mysqld_conf_next; $i<@mysql_conf; $i++) {
                  chomp $mysql_conf[$i];
                  push @conf_end, $mysql_conf[$i];
              }
              $self->debug(1,"Number of lines remaining after [mysqld] section : ".@conf_end);
              $self->debug(2,"Remaining lines content: \n".join("\n",@conf_end));

              # Change/add parameters
              for my $option (keys(%{$server->{options}})) {
                  if ( exists($indexes{$option}) ) {
                      $self->debug(1,"Replacing configuration line ".($indexes{$option}+1));
                      $mysql_conf[$indexes{$option}] = $option . '=' .  $server->{options}->{$option};
                  } else {
                      if ( ! $server_section_found ) {
                          $self->debug(1,"Adding [mysqld] section at configuration line ".($mysqld_conf_next+1));
                          $mysql_conf[$mysqld_conf_next] = "";
                          $mysqld_conf_next++;
                          $mysql_conf[$mysqld_conf_next] = "[mysqld]";
                          $mysqld_conf_next++;
                      }
                      $self->debug(1,"Adding configuration line ".($mysqld_conf_next+1));
                      $mysql_conf[$mysqld_conf_next] = $option . '=' .  $server->{options}->{$option};
                      $mysqld_conf_next++;
                  }
              }
              if ( @conf_end ) {
                  $self->debug(1,"Merging last part of initial configuration at new conf line ".($mysqld_conf_next+1)." (length=".@conf_end.")");
                  for (my $i=0; $i<@conf_end; $i++) {
                      $mysql_conf[$mysqld_conf_next+$i] = $conf_end[$i];
                  }
              }

              # Update option file
              my $mysql_conf_content = join "\n", @mysql_conf;
              $mysql_conf_content .= "\n";
              $fh->set_contents(encode_utf8($mysql_conf_content));
              my $changes = $fh->close();
              if ( $changes < 0 ) {
                  $self->warn("Error updating MySQL server parameters");
              }
          }

      } else {
          $self->debug(1,"Cannot check MySQL server configuration as server is remote (".$server->{host}.")");
      }


      # Configure server

      if ( $self->mysqlCheckAdminPwd($server) ) {
          $self->error("Failed to check/configure admin user/pwd for server $server->{host}");
          next;
      }

      # Configure global users

      for my $user_e (keys(%{$server->{users}})) {
          my $user = unescape($user_e);
          $self->info("Granting user $user access to all databases on server $server_name...");
          my $user_params = $server->{users}->{$user_e};
          if ( $self->mysqlAddUser(undef,$user,$user_params->{password},$user_params->{rights},$user_params->{shortPwd},$server) ) {
              $self->error("Error granting user $user access to all databases on server $server_name");
              next;
          }
      }

      $self->flushPrivileges($server);

      # Mark the server as enabled
      $servers->{$server_name}->{enabled} = 1;

  }


  # Loop over databases

  for my $database (sort(keys(%{$databases}))) {
      $self->info("Configuring database ".$database);
      my $server = $servers->{$databases->{$database}->{server}};
      # Just in case, normally forbidden by PAN schema
      unless ( $server ) {
          $self->error("Error retrieving server name for database $database");
      }

      # Do not attempt to configure database if an error occured configuring the server hosting it
      unless ( $server->{enabled} ) {
          $self->warn("Database $database configuration skipped due to server ".$databases->{$database}->{server}." configuration error.");
          next;
      }

      # Create database
      my $init_script = undef;
      my $createDb = $databases->{$database}->{createDb};
      if ( $databases->{$database}->{initScript} ) {
          if ( $databases->{$database}->{initScript}->{file} ) {
              $init_script = $databases->{$database}->{initScript}->{file};
          } elsif ( $databases->{$database}->{initScript}->{content} ) {
              $init_script = '/tmp/' . $database . '-init.mysql';
              my $fh = CAF::FileWriter->new($init_script, log => $self);
              print $fh encode_utf8($databases->{$database}->{initScript}->{content});
              $changes = $fh->close();
              if ( $changes < 0 ) {
                  $self->error("Error creating database $database init script ($init_script)");
                  next;
              }
          } else {
              $self->warn('Neither script file nor script content specified. Internal error');
          }
      }
      if ( $self->mysqlAddDb($database,$init_script,$databases->{$database}->{initOnce},$createDb) ) {
          $self->error("Error creating database $database on server $server->{host}");
          next;
      }

      # Alter tables if initOnce=0 (database was initialized).
      # initOnce will have been reset to 0 by mysqlAddDb() if the database was not existing before.
      unless ( $databases->{$database}->{initOnce} ) {
          while ( (my $table, my $table_attrs) = each(%{$databases->{$database}->{tableOptions}}) ) {
              $self->info("Setting options for table $table in database $database");
              if ( $self->mysqlAlterTable($database,$table,$table_attrs) ) {
                  $self->error("Error changing table $table characteristics");
                  next;
              }
          }
      }

      # Configure users
      for my $user_e (keys(%{$databases->{$database}->{users}})) {
          my $user = unescape($user_e);
          $self->info("Configuring user $user access to database $database...");
          my $user_params = $databases->{$database}->{users}->{$user_e};
          if ( $self->mysqlAddUser($database,$user,$user_params->{password},$user_params->{rights},$user_params->{shortPwd}) ) {
              $self->error("Error granting user $user access to database $database");
              next;
          }
      }

      $self->flushPrivileges($server);

  }


  return 0;
}


# Flush privileges on a given server.
#
# Arguments :
#  server : hash describing MySQL server to use (see schema)
sub flushPrivileges
{
    my ($self, $server) = @_;
    # Ensure privileges are applied
    my $status = $self->mysqlExecCmd($server,"FLUSH PRIVILEGES");
    if ( $status ) {
        $self->warn("Error flushing privileges on server $server->{host}");
    }
}


# Function to execute silently a mysql command. Host, user and password are retrived
# from server argument. stdout and stderr are  not displayed, except if
# debug level >= 2. Command may be any MySQL command or a script.
# Function take cares of command quoting and addition of --exec if needed
# Returns status code from the command (0 if success)
#
# Arguments :
#  server : hash describing MySQL server to check (see schema)
#  command : mysql command to execute. Can be a literal command or a script if preceded by 'source'. Should not be quoted.
#  database : database to apply the command to (optional, in particular in case of scripts)
sub mysqlExecCmd
{
    my $function_name = "mysqlExecCmd";
    my ($self,$server,$command,$database) = @_;

    unless ( $server ) {
        $self->error("$function_name : 'server' argument missing");
        return 1;
    }

    unless ( $command ) {
        $self->error("$function_name : 'command' argument missing");
        return 1;
    }

    my @cmd_array = ("mysql", "-h", $server->{host},
                     "-u", $server->{adminuser});
    if ( $server->{adminpwd} && (length($server->{adminpwd}) > 0) ) {
        push @cmd_array, "--password=$server->{adminpwd}";
    }
    if ( $database && (length($database) > 0) ) {
        push @cmd_array, $database;
    }
    push @cmd_array, "--exec", $command;
    my $cmd_string = join " ",@cmd_array;
    $self->debug(2,"$function_name : executing MySQL command <<<".$cmd_string.">>>");

    my $cmd = CAF::Process->new(\@cmd_array,
                                log => $self);
    my $output = $cmd->output();      # Also execute the command
    my $status = $?;
    if ( $status ) {
        $self->debug(2,"MySQL error : $output");
    }

    return $status
}


# Function to check and if necessary/possible change MySQL administrator password
# Returns 0 in case of success.
#
# User is added for localhost and server indicated in options.
#
# Arguments :
#  server : hash describing MySQL server to check (see schema)
sub mysqlCheckAdminPwd
{
    my $function_name = "mysqlCheckAdminPwd";
    my ($self,$server) = @_;
    my $test_cmd = "use mysql";

    unless ( $server ) {
        $self->error("$function_name : 'server' argument missing");
        return 0;
    }

    my $status = 1;  # Assume failure by default

    # First check if administrator account is working without password for either the specified server host or localhost
    my $admin_pwd_saved = $server->{adminpwd};
    my $server_host_saved = $server->{host};
    $server->{adminpwd} = '';
    my @db_hosts = ($server->{host}, 'localhost');
    while ( $status && @db_hosts ) {
        $server->{host} = shift @db_hosts;
        $self->debug(1, "$function_name : checking if user $server->{adminuser} has access ",
                     "to $server->{host} without password");
        $status = $self->mysqlExecCmd($server,$test_cmd);
    }

    # If previous test fails, administrator has a password set, test the password specified in the configuration.
    # This is done both for server host and localhost, in case that just one works. If just one works, force
    # reinitialization of the password.
    if ( $status ) {
        $server->{adminpwd} = $admin_pwd_saved;
        $status = 0;
        for my $host ($server_host_saved, 'localhost') {
            $server->{host} = $host;
            $self->debug(1, "$function_name : checking if user $server->{adminuser} has access ",
                         "to $server->{host} with password '$server->{adminpwd}'");
            my $this_status = $self->mysqlExecCmd($server,$test_cmd);
            if ( $this_status ) {
                $status = 1;
            } else {
                # adminhost is a special feature to handle initial admin creation when it should be done using localhost
                $server->{adminhost} = $server->{host};
            }
        }
    } else {
        $self->debug(1,"$function_name : MySQL administrator ($server->{adminuser}) password not set on $server->{host}");
        $status = 1;  # Force initialization of password
        # adminhost is a special feature to handle initial admin creation when it should be done using localhost
        $server->{adminhost} = $server->{host};
    }

    # Restore normal server host
    $server->{host} = $server_host_saved;

    # If it fails, try to change it assuming a password has not yet been set (even if previous test failed)
    if ( $status ) {
        $self->debug(1,"$function_name : trying to set administrator password on $server->{host}");
        $status = $self->mysqlAddUser(undef,$server->{adminuser},$admin_pwd_saved,'ALL',0,$server);
        if ( $status ) {
            if ( ($server->{host} ne $this_host_full) && ($server->{host} ne 'localhost') ) {
                $self->warn("Error setting administrator password on server $server->{host} ",
                            ": check access is allowed with full privileges for $server->{adminuser} on $this_host_full");
            } else {
                $self->warn("Error setting administrator password on server ".$server->{host}.". Trying to continue...");
            }
        } else {
            $self->debug(1,"$function_name : administrator password successfully set on $server->{host}");
        }
    } else {
        $self->debug(1,"$function_name : MySQL administrator password check succeeded");
    }

    $server->{adminpwd} = $admin_pwd_saved;
    $server->{adminhost} = undef;

    return $status;
}


# Function to add a database user for the product.
# Returns 0 in case of success (user already exists with the right password
# or successful creation)
#
# Arguments (optional) :
#     Database : database to grant access to (can be database.table for a specific table)
#     User : DB user to create.
#     Password : password for the user.
#     DB rights : rights to give to the user. Can be a string or an array. Defaults to 'ALL'
#     Short password hash : true/false. Default : false.
#     server : hash describing MyQSL server to use. Used only if database undefined (global users).
sub mysqlAddUser
{
    my $function_name = "mysqlAddUser";
    my ($self,$database,$db_user,$db_pwd,$db_rights,$short_pwd_hash,$server) = @_;

    if ( $database ) {
        if ( $server ) {
            $self->warn("'server' argument defined but ignored ('database' present)");
        } else {
            # Must exist at this point (enforced by PAN schema and checked previously)
            $server = $servers->{$databases->{$database}->{server}};
        }
    } else {
        if( $server ) {
            $database = '*.*';
        } else {
            $self->error("$function_name : 'database' or 'server' argument missing");
            return 0;
        }
    }

    unless ( $db_user ) {
        $self->error("$function_name : 'db_user' argument missing");
        return 0;
    }

    unless ( defined($db_pwd) ) {
        $self->error("$function_name : 'db_pwd' argument missing");
        return 0;
    }

    unless ( $db_rights ) {
        $self->error("$function_name : 'db_rights' argument missing");
        return 0;
    }

    unless ( defined($short_pwd_hash) ) {
        $short_pwd_hash = 0;
    }

    if ( uc($db_rights) eq "ALL" ) {
        $db_rights = "ALL PRIVILEGES";
    }

    if ( $database !~ /^\s*(?:\w+|\*)\.(?:\w+|\*)\s*$/ ) {
        $database .= ".*";
    }

    # If user has format user@host, split it in user and host.
    my ($userid,$user_host) = split /@/, $db_user;
    if ( ! $user_host ) {
        if ( $server ) {
            $user_host = $server->{host};
        }
    }

    # If db_rights is an array, convert to a string
    if ( ref($db_rights) eq 'ARRAY' ) {
        $db_rights = join ",", @$db_rights;
    }

    # Allow the user to connect both from localhost and real host name.
    # To handle initial creation of admin user where only one of them can be used, allow hostname
    # used for administration to be a different value than actual host name (e.g. localhost).
    my @db_hosts = ($user_host);
    if ( $user_host eq $this_host_full ) {
        push @db_hosts,'localhost';
    }
    my $admin_server = $server;
    if ( defined($server->{adminhost}) ) {
        $admin_server->{host} = $server->{adminhost};
    }

    my $status = 0;
    for my $host (@db_hosts) {
        $self->debug(1, "$function_name : Adding MySQL connection account for user $userid on $host ",
                     "(database=$database) using admin host ".$admin_server->{host});
        $status = $self->mysqlExecCmd($admin_server, "grant $db_rights on $database to \"$userid\"\@\"$host\" identified by \"$db_pwd\" with grant option");
        if ( $status ) {
            # Error already signaled by caller
            $self->debug(1,"$function_name: Failed to grant access to $userid on database $database (host=$host)");
            return $status;
        } else {
            # Update the password to use for next command in case it was updated
            # by the previous command.
            if ( ($database eq '*.*') && ($host eq $admin_server->{host}) && ($userid eq $admin_server->{adminuser}) ) {
                $admin_server->{adminpwd} = $db_pwd;
            }
        }

        # Backward compatibility for pre-4.1 clients, like perl-DBI-1.32
        if ( $short_pwd_hash ) {
            $self->debug(1,"$function_name : Defining password short hash for $userid on $host)");
            $status = $self->mysqlExecCmd($admin_server,"set password for '$userid'\@'$host' = OLD_PASSWORD('$db_pwd')");
            if ( $status ) {
                # Error already signaled by caller
                $self->debug(1,"Failed to define password short hash for $userid on $host");
                return $status;
            }
        }
    }

    return $status;
}


# Function to add a database
# Returns 0 in case of success (database already exists with the right password
# or successful creation)
#
# Arguments :
#  database : database to create
#  script   : script to create the database and tables if it doesn't exist (optional)
#  initOnce : execute script only if database wasn't existing yet (Default: false, always reexecute script).
#             initOnce is reset to 0 if database was not existing yet to allow other initializtion to proceed.
#  createDb : if false, execute the script without creating the database before
sub mysqlAddDb
{
  my $function_name = "mysqlAddDb";
  my ($self, $database, $script, $initOnce, $createDb) = @_;
  my $status = 0;

  unless ( $database ) {
      $self->error("$function_name : 'database' argument missing");
      return 0;
  }

  unless ( defined($initOnce) ) {
      $initOnce = 0;
  }

  unless ( defined($createDb) ) {
      $createDb = 1;
  }

  my $db_found = 0;
  my $server = $servers->{$databases->{$database}->{server}};

  $self->debug(1, "$function_name : checking if database $database already exists");
  $status = $self->mysqlExecCmd($server,"use $database");

  if ( $status ) {
      $self->debug(1,"$function_name : database $database not found");
      if ( $createDb ) {
          $self->debug(1,"$function_name : creating database $database");
          $status = $self->mysqlExecCmd($server,"CREATE DATABASE ".$database);
          if ( $status ) {
              $self->debug(1,"Error creating database $database (status=$status)")
          }
      } else {
          $self->debug(1,"$function_name : skipping creation of the database $database");
      }
  } else {
      $db_found = 1;
      $self->debug(1,"$function_name : database $database found");
      $status = 0;
  }

  if ( defined($script) ) {
      if ( $db_found && $initOnce ) {
          $self->debug(1,"$function_name :  skipping execution of database initialization script (database already created)");
      } else {
          $databases->{$database}->{initOnce} = 0;
          $self->debug(1,"$function_name :  executing the database initialization script");
          if ( $createDb ) {
              $status = $self->mysqlExecuteScript($server, $script, $database);
          } else {
              $status = $self->mysqlExecuteScript($server, $script);
          }
          if ( $status ) {
              $self->warn("Error executing initialization script ($script) for database $database");
          }
      }
  } elsif ( (! $db_found) && (! $createDb) ) {
      $self->error("$function_name : the database does not exist and the initialization script is not defined");
      return 1;
  }

  return($status);
}


# Function to execute a MySQL Script
# Returns 0 in case of success
#
# Arguments :
#  server : hash describing MySQL server to check (see schema)
#  script : script to create the database and tables if it doesn't exist (optional)
#  database : database to apply the script to (optional)
sub mysqlExecuteScript
{
    my $function_name = "mysqlExecuteScript";
    my ($self, $server, $script, $database) = @_;
    my $status = 0;

    unless ( $server ) {
        $self->error("$function_name : 'server' argument missing");
        return 0;
    }

    unless ( $script ) {
        $self->error("$function_name : 'script' argument missing");
        return 0;
    }

    $status = $self->mysqlExecCmd($server,"source $script",$database);
    if ( $status ) {
        $self->debug(1,"$function_name: Error executing script $script");
    }

    return $status;
}


# Function to change table characteristics
# Returns 0 in case of success
#
# Arguments :
#  database : containing the table to alter
#  table : table to alter
#  options   : hash reference of options to apply to table
sub mysqlAlterTable
{
    my $function_name = "mysqlAlterTable";
    my ($self,$database,$table,$options) = @_;
    my $status = 0;

    unless ( $database ) {
        $self->error("$function_name : 'database' argument missing");
        return 0;
    }

    unless ( $table ) {
        $self->error("$function_name : 'table' argument missing");
        return 0;
    }

    unless ( $options ) {
        $self->error("$function_name : 'options' argument missing");
        return 0;
    }

    my $server = $servers->{$databases->{$database}->{server}};

    $self->debug(1,"$function_name : checking if database $database already exists");
    $status = $self->mysqlExecCmd($server,"use $database");
    if ( $status ) {
        $self->debug(1,"$function_name : database $database not found");
        return $status;
    }

    while ( (my $option_e, my $value) = each(%$options) ) {
        my $option = unescape($option_e);
        my $value_token = '';
        if ( $value ) {
            $value_token = "=$value";
        }
        $self->debug(1,"$function_name : altering table $table in $database: $option$value_token");
        $status = $self->mysqlExecCmd($server,"ALTER TABLE $table $option$value_token",$database);
        if ( $status ) {
            $self->debug(1,"$function_name: Error creating database $database (status=$status)")
        }
    }
}

1; #required for Perl modules
