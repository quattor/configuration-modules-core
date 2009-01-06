# ${license-info}
# ${developer-info}
# ${author-info}

#
# Example NCM Component with NVA API config access
#
###############################################################################

package NCM::Component::nscd;
#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
use NCM::Check;
use LC::Check;
use File::Temp;
use File::Copy qw(copy);

@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
$NCM::Component::NoActionSupported=1;

my $cfgfile='/etc/nscd.conf';
my $p ='/software/components/nscd';

##########################################################################
sub Configure($$) {
##########################################################################
  my ($self,$config)=@_;
  my $changes;
  my $RealNoAction = $NoAction;
  # need to turn this off while working on the temp file.
  undef($NoAction);

  my $tmpfile = $cfgfile.".tmp"; # same dir, don't have to worry about a race
  if( -e $tmpfile) {
    unlink($tmpfile);
  }

  if ( -r $cfgfile) {
    if (!copy($cfgfile, $tmpfile)) {
      $self->warn("cannot create $tmpfile: $!, giving up");
      return 0;
    }
  } else {
    $self->info("$cfgfile does not exist (yet)");
  }

  # add ourselves to the top
  $changes = NCM::Check::lines($tmpfile,
			       good => '## Warning: file partially controlled by ncm-nscd',
			       goodre => '^## Warning: file partially controlled.*',
			       linere => '^## Warning: file partially controlled.*',
			       add => 'first',
			       keep => 'first'
			      );
  if($changes) {
    $self->verbose("added NCM marker to top of file");
  }

  # check global options we know about
  my @global_opts = (
		     'logfile',
		     'debug-level',
		     'threads',
		     'max-threads',
		     'server-user',
		     'stat-user',
		     'reload-count',
		     'paranoia',
		     'restart-interval'
		    );

  for my $cfgname (@global_opts) {
    if ($config->elementExists($p."/".$cfgname )) {
      my $value=$config->getValue($p."/".$cfgname );
      $self->debug(5, "global option \"$cfgname\" = \"$value\"");

      $changes=NCM::Check::lines($tmpfile,
			good => "\t$cfgname\t\t$value",
			goodre => "^\\s*$cfgname\\s+$value",
			linere => ".*$cfgname.*",
			add => 'last',
			keep => 'first'
		       );
      if ($changes) {
	$self->info("set global option \"$cfgname\" = \"$value\"");
      } else {
	$self->verbose("global option \"$cfgname\" = \"$value\" already OK");
      }
    } else {
      $self->debug(5, "global option \"$cfgname\" not set in profile");
    }
  }

  # check per-service options we know about
  my @services = ('passwd', 'group', 'hosts');
  my @service_opts = (
		      'enable-cache',
		      'positive-time-to-live',
		      'negative-time-to-live',
		      'suggested-size',
		      'check-files',
		      'persistent',
		      'shared',
		      'max-db-size',
		      'auto-propagate'
		     );

  for my $service (@services) {
    for my $cfgname (@service_opts) {

      if ($config->elementExists($p."/".$service."/".$cfgname )) {
	my $value=$config->getValue($p."/".$service."/".$cfgname );
	$self->debug(5, "service \"$service\" option \"$cfgname\" = \"$value\"");
	
	$changes=NCM::Check::lines($tmpfile,
				   good => "\t$cfgname\t$service\t\t$value",
				   goodre => "^\\s*$cfgname\\s+$service\\s+$value",
				   linere => ".*$cfgname\\s+$service.*",
				   add => 'last',
				   keep => 'first'
				  );
	if ($changes) {
	  $self->info("set service \"$service\" option \"$cfgname\" = \"$value\"");
	} else {
	  $self->verbose("service \"$service\" option \"$cfgname\" = \"$value\" already OK");
	}
      } else {
	$self->debug(5, "service \"$service\" option \"$cfgname\" not set in profile");
      }
    }
  }


  # check whether we've changed anything
  $NoAction = $RealNoAction;
  $changes = LC::Check::file($cfgfile,
			       source => $tmpfile,
			       owner => 'root',
			       group => 'root',
			       backup => '.ncmorig',
			       mode => '0444');
  if ($changes && !$NoAction) {
    my $s;
    # make SELinux happy
    if (-x '/sbin/restorecon') {
      $s=`/sbin/restorecon -v $cfgfile 2>&1`;
      chomp($s);
      if ($?) {
	$self->warn("cannot restore SELinux context for $cfgfile:\n$s");
      } else {
	$self->info("restored SELinux context for $cfgfile:\n$s");
      }
    }

    $s=`/sbin/service nscd condrestart 2>&1`;
    chomp($s);
    if ($? && $s) {
      # also get bad return code if the service wasn't running, so need to check for actual error msg
      $self->error("can't restart service, changes not activated:\n$s");
    } else {
      $self->info("service nscd has been condrestart-ed");
    }
  } elsif ($changes) {
    $self->info("some changes, would need to restart nscd");
  } else {
    $self->info("no changes.");
  }

  if( -e $tmpfile) {
    unlink($tmpfile);
  }

  return; # return code is not checked.

}

1; # Perl module requirement.

### Local Variables: ///
### mode: perl ///
### End: ///
