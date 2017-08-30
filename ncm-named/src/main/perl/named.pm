#${PMcomponent}

use parent qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
use Readonly;
use Encode qw(encode_utf8);

use CAF::FileEditor qw(ENDING_OF_FILE);
use CAF::FileWriter;
use CAF::Process;
use CAF::Service;

our $NoActionSupported = 1;

# Define paths for convenience.
Readonly our $NAMED_CONFIG_FILE => '/etc/named.conf';
Readonly our $NAMED_SYSCONFIG_FILE => '/etc/sysconfig/named';
Readonly our $RESOLVER_CONF_FILE => '/etc/resolv.conf';

Readonly my $NAMED_SERVICE => "named";


sub Configure
{

    my ($self, $config) = @_;

    # Get config into a perl Hash
    my $named_config = $config->getElement($self->prefix())->getTree();

    # Check if named server must be enabled

    # $server_enabled is a tri-state variable (undefined, 0 or 1)
    my $server_enabled;
    if ( defined($named_config->{start}) ) {
        if ( $named_config->{start} ) {
            $server_enabled = 1;
        } else {
            $server_enabled = 0;
        }
    }


    # Update resolver configuration file with appropriate servers

    $self->info("Checking $RESOLVER_CONF_FILE...");
    my $fh = CAF::FileEditor->new($RESOLVER_CONF_FILE,
                                  backup => '.old',
                                  log => $self,
                                 );
    if ( $named_config->{servers} || ($server_enabled && $named_config->{use_localhost}) ) {
        $fh->remove_lines(q(^(?i)\s*nameserver\s+),
                          q(no good line));
        if ( $server_enabled && $named_config->{use_localhost} ) {
            print $fh "nameserver 127.0.0.1\t\t# added by Quattor\n";
        }
        for my $named_server (@{$named_config->{servers}}) {
            print $fh "nameserver $named_server\t\t# added by Quattor\n";
        }

        if ( $named_config->{search} ) {
            $fh->add_or_replace_lines("^\\s*search\\s*.*",
                                      "^\\s*search\\s*@{$named_config->{search}}",
                                      "search @{$named_config->{search}}\n",
                                      ENDING_OF_FILE,
                                     );
        }
    }

    # options
    if ( $named_config->{options} ) {
        $fh->add_or_replace_lines("^\\s*options\\s*.*",
                                  "^\\s*options\\s*@{$named_config->{options}}",
                                  "options @{$named_config->{options}}\n",
                                  ENDING_OF_FILE,
                                 );
    }

    $self->debug(1,"New $RESOLVER_CONF_FILE contents:\n".$fh->stringify()."\n");
    my $update_disabled = $fh->noAction();
    my $changes = $fh->close();
    unless ( defined($changes) || $update_disabled ) {
        $self->error("error modifying $RESOLVER_CONF_FILE");
    }


    # Do not do named configuration if startup script is not present (service not configured).
    # FIXME: to be replaced by CAF::Service if/when it supports chkconfig actions

    my $NAMED_SERVICE = "named";
    my $cmd = CAF::Process->new(["/sbin/chkconfig", "--list", $NAMED_SERVICE], log => $self);
    $cmd->output();      # Also execute the command
    if ( $? ) {
        $self->debug(1,"Service $NAMED_SERVICE doesn't exist on current host. Skipping $NAMED_SERVICE configuration.");
        return;
    }


    # Update named configuration file with configuration embedded in the configuration
    # or with the reference file, if one of them has been specified

    my $named_root_dir = $self->getNamedRootDir();
    my $named_config_file_path = $named_root_dir.$NAMED_CONFIG_FILE;
    my ($named_config_contents, $server_changes);

    if ( $named_config->{serverConfig} ) {
        $self->info("Checking $NAMED_SERVICE configuration ($named_config_file_path)...");
        $named_config_contents = encode_utf8($named_config->{serverConfig});
    } elsif ( $named_config->{configfile} ) {
        $self->info("Checking $NAMED_SERVICE configuration ($named_config_file_path) using $named_config->{configfile}...");
        my $src_fh = CAF::FileEditor->new($named_config->{configfile}, log => $self);
        $src_fh->cancel();
        $named_config_contents = $src_fh->stringify();
        $src_fh->close();
    }

    if ($named_config_contents) {
        $fh = CAF::FileWriter->new($named_config_file_path,
                                   backup      => '.ncm-named',
                                   owner       => 'root',
                                   mode        => 0644,
                                   log => $self,
            );
        print $fh $named_config_contents;
        $update_disabled = $fh->noAction();
        $server_changes = $fh->close();
        unless ( defined($server_changes) || $update_disabled ) {
            $self->error("error updating $named_config_file_path");
            return;
        }

        $self->updateServiceState($NAMED_SERVICE,$server_enabled,$server_changes);
    } else {
        $self->verbose("No config contents for $NAMED_SERVICE configuration ($named_config_file_path)");
    }

}


# This function is used to update permanent and live state of the named
# service. It accepts 3 arguments:
#   - service_name: the name of the service
#   - service_enabled: 1 if service is enable, 0 if disabled, undef if
#                      undefined (nothing done)
#   - config_changes: non-zero if a config file was changed. Will trig
#                     a restart if the service is already running.
#
# FIXME: to be replaced by CAF::Service when/if a similar method is provided.
#
sub updateServiceState
{

    my ($self, $service_name, $service_enabled, $config_changes) = @_;
    unless ( $service_name ) {
        $self->error("updateServiceState(): missing arguments (internal error)");
        return;
    }

    # Enable named service

    my $reboot_state;
    if ( $service_enabled ) {
        $self->info("Enabling service $service_name...");
        $reboot_state = "on";
    } else {
        $self->info("Disabling service $service_name...");
        $reboot_state = "off";
    }
    my $cmd = CAF::Process->new(["/sbin/chkconfig", "--level", "345", $service_name, $reboot_state], log => $self);
    $cmd->output();      # Also execute the command
    if ( $? ) {
        $self->error("Error defining service $service_name state for next reboot.");
    }

    # Start named if enabled and not yet started.
    # Stop named if running but disabled.
    # Restart after a configuration change if enabled and started.
    # Do nothing if the 'start' property is not defined.

    $self->debug(1,"Checking if service $service_name is started...");
    my $named_started = 1;
    # FIXME: to be replaced by CAF::Service if/when it offers a status() method
    $cmd = CAF::Process->new(["/sbin/service", $service_name, "status"], log => $self);
    $cmd->output();      # Also execute the command
    if ( $? ) {
        $self->debug(1,"Service $service_name not running.");
        $named_started = 0;
    } else {
        $self->debug(1,"Service $service_name is running.");
    }

    my $action;
    if ( defined($service_enabled) ) {
        if ( $service_enabled ) {
            if ( ! $named_started ) {
                $action = 'start';
            } elsif ( $config_changes ) {
                $action = 'restart';
            }
        } else {
            if ( $named_started ) {
                $action = 'stop';
            };
        }
    }

    if ( $action ) {
        $self->info("Doing a $action of service $service_name...");
        my %opt;
        $opt{timeout} = 0;
        my $srv = CAF::Service->new([$service_name], log => $self, %opt);
        $srv->$action();
        if ( $? ) {
            $self->debug(1,"Failed to update service $service_name state.");
            $named_started = 0;
        }
    } else {
        $self->debug(1,"No need to start/stop/restart service $service_name");
    }

    return;
}


# Retrieve named root dir (used when named is chrooted) from sysconfig file
# and check that it is a valid path, as defined by ROOTDIR variable.
# If the sysconfig file is not present or the ROOTDIR variable is not
# explicitely defined, assume that named is not run chrooted and return an
# empty string.
#
# Return value : named root dir if defined or the empty string
#
sub getNamedRootDir
{

    my $self = shift;
    my $named_root_dir = "";

    my $fh = CAF::FileReader->new($NAMED_SYSCONFIG_FILE, log => $self);
    unless ( defined($fh) ) {
        $self->debug(1,"$NAMED_SYSCONFIG_FILE not found, assume named is not chrooted");
        return "";
    }

    $fh->seek_begin();
    while ( my $line = <$fh> ) {
        if ($line =~ /^\s*ROOTDIR\s*=\s*(.*)(\s+#.*)*$/) {
            $named_root_dir = $1;
            chomp($named_root_dir);
        }
    }

    $fh->close();

    if ( !$named_root_dir ) {
        $self->debug(1,"No named root directory definition found in $NAMED_SYSCONFIG_FILE, assume named is not chrooted");
    } elsif  ( $named_root_dir =~ m{^['"]?(/[-\w\./]+)['"]?$}) {
        $named_root_dir = $1;
        $self->debug(1,"named root dir successfully retrieved from $NAMED_SYSCONFIG_FILE: $named_root_dir");
    } else {
        $self->error("Named chroot directory (ROOTDIR in $NAMED_SYSCONFIG_FILE) is not a valid path: $named_root_dir");
    }

    return $named_root_dir;
}

1; #required for Perl modules
