# ${license-info}
# ${developer-info}
# ${author-info}

#######################################################################
#
# NCM::sendmail : NCM component - configure sendmail
#
# Copyrigth (c) 2004 Jan Iven <jan.iven@cern.ch> , CERN
#
#######################################################################

package NCM::Component::sendmail;

#
# a few standard statements, mandatory for all components
#

use strict;
use Socket;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

use NCM::Check;
# mail aliases DB
require DB_File;
use Fcntl;


my $cfgservice='sendmail';
my $cfgfilemc='/etc/mail/sendmail.mc';
my $cfgfilecf='/etc/mail/sendmail.cf';
my $localuserfile='/etc/mail/local-users';
my $mailaliasesdb='/etc/aliases.db';
my $etclogindefs='/etc/login.defs';
my $cfgpathuserdomain='/software/components/sendmail/userdomain';
my $cfgpathsmtpserver='/software/components/sendmail/smarthost';
my $cfgpathallowexternal='/software/components/sendmail/allowexternal';
my $cfglocalusers='/software/components/sendmail/localusers';

my $compname = "NCM-sendmail";

sub service_running {
  my ($self,$srvc)=@_;
  my $out=`/sbin/service $srvc status`;
  my $return = 0;
  if (!($? >> 8) || $out =~/is running/ || $out =~/dead but pid/) {
    $return= 1;
  }
  $self->info("service $srvc is ".($return ? '' : 'not ')."running");
  return $return;
}

sub restart_service {
  my ($self,$srvc)=@_;
  if ($self->service_running($srvc)) {
    my $s=`/sbin/service $srvc restart`;
    if ($?) {
      $self->error("can't restart $s service, changes not activated.");
    } else {
      $self->info("service $srvc has been restarted");
    }
  }
}

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  if (-r $cfgfilemc && -r $cfgfilecf) {

    # Modify sendmail macro configuration
    ## Set From header Masquerading
    if($config->elementExists($cfgpathuserdomain)) {
      my $cfgvalueuserdomain=$config->getValue($cfgpathuserdomain);
      NCM::Check::lines($cfgfilemc,
			linere => ".*MASQUERADE_AS.*",
			goodre => "^MASQUERADE_AS.\`".$cfgvalueuserdomain."\'.dnl",
			good   => "MASQUERADE_AS(`".$cfgvalueuserdomain."')dnl",
		       );
      $self->info("masquerade as host:  $cfgvalueuserdomain");

      ## Set Return-Path Masquerading
      NCM::Check::lines($cfgfilemc,
			linere => ".*FEATURE.*masquerade_envelope.*",
			goodre => "^FEATURE.masquerade_envelope.dnl",
			good   => "FEATURE(masquerade_envelope)dnl",
		       );
      $self->info("masquerading header and envelope");

      ## Set relay all unqualified names (ie. names without @host) to the relay host
      # this may break user .forward files? apparently we don't check these anymore?
      NCM::Check::lines($cfgfilemc,
			linere => ".*define.*LOCAL_RELAY.*",
			goodre => "^define.\`LOCAL_RELAY',`".$cfgvalueuserdomain."\'.dnl",
			good   => "define(`LOCAL_RELAY',`".$cfgvalueuserdomain."')dnl",
			add    => 'last',
		       );
      $self->info("unqualified users relayed via $cfgvalueuserdomain");

      ## names to except from the unqualified name relay.
      # root mail won't work otherwise (still needs a .forward in most cases)
      my @localuserslist = ();
      if($config->elementExists($cfglocalusers)) {
        @localuserslist = map { $_->getValue() } $config->getElement($cfglocalusers)->getList();
      }
      # if not set explicitly, we'll guess all non-AFS users that don't figure in the alias table.
      if ($#localuserslist < 0) {
	$self->info("will guess the list of local users for unqualified relay");

	@localuserslist = ("root");

	# local sendmail alias list
	my %aliases;
	tie %aliases, "DB_File", $mailaliasesdb, O_RDONLY;	# expect trailing \0 for keys & values
	my $num_aliases= scalar keys(%aliases);
	if ($num_aliases < 0) {
	  $self->warn("no local mail aliases defined in $mailaliasesdb");
	} else {
	  $self->debug(2,"found $num_aliases local mail aliases defined in $mailaliasesdb");
	}

	# minimum/maximum user id, use values for "useradd"
	my $min_uid=500;
	my $max_uid=60000;
	if (! open(DEFS, "<$etclogindefs")) {
	  $self->warn("using hardcoded min/max local uid, cannot read $etclogindefs: $!");
	}
	while(<DEFS>) {
	  if (m/^\s*UID_MIN\s+(\d+)/) {
	    $min_uid=$1;
	    next;
	  }
	  if (m/^\s*UID_MAX\s+(\d+)/) {
	    $max_uid=$1;
	    next;
	  }
	}
	close DEFS;

	# loop over all acounts
	setpwent();
	while(my ($name,undef,$uid,undef,
                      undef,undef,undef,$dir,undef,undef) = getpwent()) {
	  if ($dir =~ m:^/afs:) {
	    $self->debug(2,"skipping AFS account $name");
	    next;
	  } elsif ( ! -d $dir ) {
	    $self->debug(2,"skipping account $name without home dir");
	    next;
	  }
	  if ($aliases{"$name\0"}) {
	    my $target = $aliases{"$name\0"};
	    $target =~ s/\0$//;
	    $self->debug(2,"skipping account $name with mail alias $target");
	    next;
	  }

	  if ($uid < $min_uid || $uid > $max_uid) {
	    $self->debug(2,"skipping account $name with uid=$uid not in [$min_uid,$max_uid]");
	    next;
	  }

	  # else: candidate
	  push (@localuserslist, $name);
	}
      }

      # stabilize order so we don't overwrite the config file randomly, remove dupes
      @localuserslist  = keys %{{ map { $_ => 1 } (sort(@localuserslist)) }};


      my $localusers=join("\n",@localuserslist)."\n";
      my $localusersline=join(",",@localuserslist);
      if($#localuserslist < 11) {
	$self->info("exception list for unqualified relay in $localuserfile: $localusersline");
      } else {
	$self->info("exception list for unqualified relay in $localuserfile has ".($#localuserslist+1)." entries: ".substr($localusersline,0,20)."...");
	$self->debug(5,"Full exception list: ".$localusersline);
      }
      LC::Check::file($localuserfile, contents => $localusers);

      NCM::Check::lines($cfgfilemc,
			linere => ".*LOCAL_USER_FILE.*",
			goodre => "^LOCAL_USER_FILE.\`".$localuserfile."'.dnl",
			good   =>  "LOCAL_USER_FILE(`".$localuserfile."')dnl",
			add    => 'last',
		       );
    } else {
      $self->info("no masquerade host defined");
      $self->info("no header/envolope masquerade");
      $self->info("no unqualified user relay (and no local user exceptions)");
    }

    ## Set the outgoing mail server
    if($config->elementExists($cfgpathsmtpserver)) {
      my $cfgvaluesmtpserver=$config->getValue($cfgpathsmtpserver);
      my $quotedsmtpserver=quotemeta($cfgvaluesmtpserver);
      NCM::Check::lines($cfgfilemc,
			linere => ".*define.*SMART_HOST.*",
			goodre => "^define.\`SMART_HOST',`".$quotedsmtpserver."\'.dnl",
			good   => "define(`SMART_HOST',`".$cfgvaluesmtpserver."')dnl",
		       );
      $self->info("using smarthost:  $cfgvaluesmtpserver");
    } else {
      $self->info("no smart host defined");
    }

    ## listen for incoming mail traffic, not just localhost-only?
    my $cfgvalueallowexternal;
    if($config->elementExists($cfgpathallowexternal)) {
      $cfgvalueallowexternal = $config->getValue($cfgpathallowexternal);
    }
    if(defined($cfgvalueallowexternal)) {
      if($cfgvalueallowexternal eq 'true') {
	my $externaldaemonoptions="Port=smtp, Name=MTA";
	NCM::Check::lines($cfgfilemc,
			linere => "^DAEMON_OPTIONS.\`Port=smtp,.*Name=MTA\'.dnl.*",
			goodre => "^DAEMON_OPTIONS.\`".$externaldaemonoptions."\'.dnl.*",
			good   => "DAEMON_OPTIONS(`".$externaldaemonoptions."')dnl",
		       );
	$self->info("sendmail will listen for external SMTP connections");
      } else {
	my $defaultdaemonoptions="Port=smtp, Addr=127.0.0.1, Name=MTA";
	NCM::Check::lines($cfgfilemc,
			linere => "^DAEMON_OPTIONS.\`Port=smtp,.*Name=MTA\'.dnl.*",
			goodre => "^DAEMON_OPTIONS.\`".$defaultdaemonoptions."\'.dnl.*",
			good   => "DAEMON_OPTIONS(`".$defaultdaemonoptions."')dnl",
		       );
	$self->info("sendmail will listen only for local SMTP connections");
      }
    } else {
      $self->info("sendmail listening options not configured");
    }


    ## add support for AFS-style ~/public/.forward (where ~/.forward wouldn't be readable)
    ## this is not configurable for now.
    my $defaultforwardre=".z/public/\.forward\..w:.z/public/\.forward:.z/\.forward\..w:.z/\.forward"; # don't bother quoting $s
    my $forwardpath = "\$z/public/.forward.\$w:\$z/public/.forward:\$z/.forward.\$w:\$z/.forward";
    NCM::Check::lines($cfgfilemc,
		      linere => ".*define.*confFORWARD_PATH.*",
		      goodre => "^define.\`confFORWARD_PATH',`".$defaultforwardre."\'.dnl",
		      good   => "define(`confFORWARD_PATH',`".$forwardpath."')dnl",
		      add    => 'last'
		     );
    $self->info("looking for .forward in:  $forwardpath");


    # Generate sendmail configuration file
    unless($NoAction) {
      my $s=`/usr/bin/m4 "$cfgfilemc" 2>&1 > "$cfgfilecf"`;
      if ($? >> 8) {
	$self->error("m4 error while converting sendmail config: $s");
      }
      $self->info("converted sendmail config $cfgfilemc -> $cfgfilecf");
    } else {
      $self->info("would convert sendmail config");
    }

    # Restart the sendmail to load the new configuration

    # Note: M4 writes a timestamp into the new file, so trying to
    # avoid needless sendmail needs more effort than just comparing
    # the old and new .cf file.

    unless($NoAction) {
      $self->restart_service($cfgservice);
    } else {
      $self->info("would restart sendmail");
    }

    $self->OK("Sendmail configured");
  } else {
    $self->warn("Sendmail config files ($cfgfilemc, $cfgfilecf) are missing. Nothing changed");
  }
  return;
}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;

  if (-r $cfgfilemc && -r $cfgfilecf) {

    # Modify sendmail macro configuration
    ## Reset From header Masquerading
    NCM::Check::lines($cfgfilemc,
		      linere => ".*MASQUERADE_AS.*",
		      goodre => "^dnl MASQUERADE_AS.*",
		      good   => "dnl MASQUERADE_AS(`mydomain.com')dnl",
		     );
    ## Reset Return-Path Masquerading
    NCM::Check::lines($cfgfilemc,
                      linere => ".*FEATURE.*masquerade_envelope.*",
                      goodre => "^dnl FEATURE.*masquerade_envelope.*",
                      good   => "dnl FEATURE(masquerade_envelope)dnl",
                     );

    ## Reset outgoing mail server
    NCM::Check::lines($cfgfilemc,
		      linere => ".*define.*SMART_HOST.*",
		      goodre => "^dnl define.*SMART_HOST.*",
		      good   => "dnl define(`SMART_HOST',`smtp.your.provider')",
		     );

    ## Reset relay all unqualified names to the relay host
    NCM::Check::lines($cfgfilemc,
		      linere => ".*define.*LOCAL_RELAY.*",
		      goodre => "^dnl define.*LOCAL_RELAY.*",
		      good   => "dnl define(`LOCAL_RELAY',`mydomain.com.')dnl",
		     );

    ## Reset local users list
    NCM::Check::lines($cfgfilemc,
		      linere => ".*LOCAL_USER.*",
		      goodre => "^dnl LOCAL_USER.*",
		      good   =>  "dnl LOCAL_USER(`root')dnl",
		     );

    ## Reset daemon options
    my $defaultdaemonoptions="Port=smtp,Addr=127.0.0.1, Name=MTA";
    NCM::Check::lines($cfgfilemc,
			linere => ".*DAEMON_OPTIONS.*",
			goodre => "^DAEMON_OPTIONS.`".$defaultdaemonoptions."\'.*",
			good   => "DAEMON_OPTIONS(`".$defaultdaemonoptions."')dnl",
		       );

    ## Reset forward path
    my $defaultforwardre=".z/\.forward\..w:.z/\.forward"; # don't bother quoting the $s
    my $defaultforwardpath="\$z/.forward.\$w:\$z/.forward";
    NCM::Check::lines($cfgfilemc,
		      linere => ".*define.*confFORWARD_PATH.*",
		      goodre => "^define.*confFORWARD_PATH.,.".$defaultforwardre."..dnl",
		      good   => "define(`confFORWARD_PATH',`".$defaultforwardpath."')dnl"
		     );

    # Generate sendmail configuration file
    unless($NoAction) {
      my $s=`/usr/bin/m4 "$cfgfilemc" 2>&1 > "$cfgfilecf"`;
      $self->info("converted sendmail config $cfgfilemc -> $cfgfilecf");
    } else {
      $self->info("would convert sendmail config");
    }

    # Restart the sendmail to load the new configuration
    unless($NoAction) {
      $self->restart_service($cfgservice);
    } else {
      $self->info("would restart sendmail");
    }

    $self->OK("Sendmail unconfigured");
  } else {
    $self->warn("Sendmail config files ($cfgfilemc, $cfgfilecf) are missing. Nothing changed");
  }

  return;
}


1; #required for Perl modules

### Local Variables: ///
### mode: perl ///
### End: ///
