# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::filecopy;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC  = LC::Exception::Context->new->will_store_all;
use NCM::Check;

use EDG::WP4::CCM::Element qw(unescape);

use File::Basename;
use File::Path;
use Encode qw(encode_utf8);

local (*DTA);

##########################################################################
sub Configure($$@) {
##########################################################################

  my ( $self, $config ) = @_;

  # Define path for convenience.
  my $base = "/software/components/filecopy";
  my $globalForceRestartPath = "$base/forceRestart";

  # Determine first if there is anything to do.
  return 0 unless ( $config->elementExists("$base/services") );

  my $changes = 0;

  # Extract the list of files to manage.
  my %files = $config->getElement("$base/services")->getHash();

  # Loop over all of the files and manage the associated services.
  my @commands;
  for my $encfname ( sort keys %files ) {

    # Convenience variables.
    my $configPath      = "$base/services/$encfname/config";
    my $restartPath     = "$base/services/$encfname/restart";
    my $forceRestartPath = "$base/services/$encfname/forceRestart";
    my $permsPath       = "$base/services/$encfname/perms";
    my $ownerPath       = "$base/services/$encfname/owner";
    my $groupPath       = "$base/services/$encfname/group";
    my $backupPath      = "$base/services/$encfname/backup";
    my $noutf8Path      = "$base/services/$encfname/no_utf8";

    # The actual file name.
    my $fname = unescape($encfname);

    # Pull in the configuration.
    my $contents = $config->getValue($configPath);

    # Now just create the new configuration file.
    # Existing file is backed up, if it exists.

    if ( !-e $fname ) {
      # Check to see if the directory needs to be created.
      my $dir = dirname($fname);
      mkpath( $dir, 0, 0755 ) unless ( -e $dir );
      if ( !-d $dir ) {
        $self->error("Can't create directory: $dir");
        next;
      }
    }

    my %file_opts;
    if ( $config->elementExists($permsPath) ) {
      my $perms = oct( $config->getValue($permsPath) );
      $file_opts{'mode'} = $perms;
    }
    if ( $config->elementExists($groupPath) ) {
      my $group = $config->getValue($groupPath);
      $file_opts{'group'} = $group;
    }
    if ( $config->elementExists($ownerPath) ) {
      my $owner_group = $config->getValue($ownerPath);
      my ($owner, $group) = split /:/, $owner_group;
      $file_opts{'owner'} = $owner;
      if ( !exists($file_opts{'group'}) && $group ) {
        $file_opts{'group'} = $group;
      }
    }

    # by default a backup is made, but this can be suppressed
    my $backup = '.old';
    if ( $config->elementExists($backupPath) ) {
      if ( $config->getValue($backupPath) eq 'false' ) {
        $backup = undef;
      }
    }

    if ( !$config->elementExists($noutf8Path) || !($config->getValue($noutf8Path) eq "true")) {
        $contents = encode_utf8($contents);
    }
    

    # LC::Check methods log a message if a change happened
    # LC::Check::status must be called independently because doing
    # the same operation in LC::Check::file, changes are not reported in
    # the return value.
    if ( $backup ) {
      $changes = LC::Check::file(
                                  $fname,
                                  backup   => $backup,
                                  contents => $contents,
                                );      
    } else {
      $changes = LC::Check::file(
                                  $fname,
                                  contents => $contents,
                                );            
    }
    $changes += LC::Check::status(
                                $fname,
                                %file_opts
    );

    # Check if the service must be restarted.
    # Default is to restart only if config file was changed.
    # Restart can be forced indepedently of changes, defining 'forceRestart'
    # properties globally or at the service level.
    my $service_restart = $changes;
    if ( ($config->getValue($forceRestartPath) eq 'true') ||
         ($config->getValue($globalForceRestartPath) eq 'true') ) {
      $service_restart = 1;
    }

    # Queue the restart command if given.
    if ( $config->elementExists($restartPath) && $service_restart ) {
      my $cmd = $config->getValue($restartPath);
      push @commands, $cmd;
    }
  }

  # Loop over all of the commands and execute them.  Do this after
  # everything to take care of any dependencies between writing
  # multiple files.
  foreach (@commands) {
    my $rc = system($_);
    $self->error("Failed restart: $_\n") if ($rc);
  }

  return 1;
}


1;    # Required for PERL modules
