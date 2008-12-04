# ${license-info}
# ${developer-info}
# ${author-info}

#
# NCM::syslog - NCM component for editing /etc/syslog.conf
#
# adds and edits entries in /etc/syslog.conf, but does NOT remove entries that
# do not appear in the template!
################################################################################

package NCM::Component::syslog;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Check;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;

  my $syslogconf = "/etc/syslog.conf";
  my $changes = 0;
  my @directives;
  my %directive_found;

  my $basepath = "/software/components/syslog";
  my @priorities;
  if ( !$config->elementExists($basepath)) {
      $self->warn("No /software/components/syslog in profile.");
      return;
  }
  my $daemontype="syslog";
  if ( $config->elementExists("$basepath/daemontype")) {
      $daemontype=$config->getValue("$basepath/daemontype");
      $syslogconf = "/etc/$daemontype.conf";
      $self->debug(2,"Daemon type set to ".$daemontype);
  }
  if ( $config->elementExists("$basepath/file")) {
      $syslogconf=$config->getValue("$basepath/file");
      $self->debug(2,"Configuration file set to ".$syslogconf);
  }
  my $fullcontrol = 0;
  my @syslogcontents = "";
  if ( $config->elementExists("$basepath/fullcontrol") && $config->getValue("$basepath/fullcontrol") ){
      $fullcontrol = 1;
      # ok, we accept only entries from the template in syslog.conf
      $self->debug(2,"fullcontrol is true");
  }
  else{
      # old style, we accept entries from other sources in syslog.conf
      $self->debug(2,"fullcontrol is not defined or false");
      open (SLC,"<$syslogconf");
      while (<SLC>) {
        if (/^\s*.*# ncm-syslog/) {
		# rsyslog directives
		chomp;
		my $l=$_;
		$l=~s/\s*# ncm-syslog.*//g;
		$directive_found{$l}=1;
		next;
	}
	push @syslogcontents,$_;
      }
      close SLC;
  }

  # Accumulate the directives such as templates, modload etc.
  my $entry = 0;
  my $configpath=${basepath}."/directives/$entry";
  while ($config->elementExists($configpath)){
      my $d=$config->getValue($configpath);
      $self->debug(2,"Directive $d requested in CDB profile");
      if (!$fullcontrol) {
		my $oldd=$directive_found{$d};
		if (!defined($oldd)) {
      			$self->debug(2,"Directive $d is new");
			$changes=1;
		} else {
      			$self->debug(2,"Directive $d already present in configuration file");
			delete $directive_found{$d};
		}
	}
      push @directives,sprintf("%-40s # ncm-syslog\n",$d) ;
      $entry ++;
      $configpath=${basepath}."/directives/$entry";
  }

  if (!$fullcontrol) {
	for my $d (keys %directive_found) {
      		$self->debug(2,"Directive $d deleted from configuration file");
		$changes=1;
	}
  }
		
     
  # Accumulate the directives
  $entry = 0;
  $configpath     = ${basepath}."/config/$entry";
  while ($config->elementExists($configpath)){
      if ( $fullcontrol ) {
          if ( $config->elementExists("$configpath/comment")){
              my $comment = $config->getValue("$configpath/comment");
              if ( $comment !~ /^#/ ){
		  $self->debug(3,"no leading # in comment, will add one.");
                  $comment = "# " . $comment;
	      }
              if ( $comment !~ /^\n/ ){
		  $self->debug(3,"no leading newline in comment, will add one.");
                  $comment = "\n" . $comment;
	      }
              if ( $comment !~ /\n$/ ){
		  $self->debug(3,"no trailing newline in comment, will add one.");
                  $comment = $comment . "\n";
	      }
              push @syslogcontents, $comment;
          }
      }
      # get action part
      my $action   = $config->getValue("$configpath/action");
      my $template   = "";
      if ( $config->elementExists("$configpath/template")) {
	  $template=";".$config->getValue("$configpath/template");
      }
      my $actionKnown = $self->KnownAction($action,@syslogcontents);
      # get selectors
      my $selectors = 0;
      my $line = "";
      my $seperator= "";
      my $selectorpath = "$configpath/selector/$selectors";
      while ($config->elementExists($selectorpath)){
	  my $facility = $config->getValue("$selectorpath/facility");
	  my $mfacility = $facility eq '*' ? '\*' : "$facility";
	  my $priority = $config->getValue("$selectorpath/priority");
	  my $mpriority = $priority eq '*' ? '\*' : "$priority";
	  if ( $fullcontrol ) {
	      # easy, just add the line
	      if ( $line ){
		  $seperator = ';'
	      }
	      $line = "$line"."$seperator$facility.$priority";
	  }
	  else{
	      # accept entries from other sources? Then we need some checks...
	      # does the action exist already?
	      if ( $actionKnown ){
		  $self->debug(2,"action $action is known already");
		  # check whether this action has an entry for this facility
		  my $facilityKnown = $self->KnownFacility($mfacility,$action,@syslogcontents);
		  if ( $facilityKnown ) {
		      $self->debug(2,"facility $facility already uses action $action");
		      # this facility used this action already, but is the priority correct?
		      if ( ! map { /^.*${mfacility}\.${mpriority}.*${action}/ } @syslogcontents ){
			  $self->debug(2, "have to fix priority for facility $facility");
			  $changes += map { s/${mfacility}\.[\w\*]+/${facility}\.${priority}/ if /^[^#].*$action/ } @syslogcontents;
		      }
		  }
		  else {
		      $self->debug(2,"facility $facility is not yet using action $action");
		      # this facility has not yet used this action, simply add it to this action
		      $changes += map { s/\s*${action}/;${facility}\.${priority}\t${action}/ unless /^#/ } @syslogcontents;
		  }
	      }
	      else{
		  $self->debug(2,"action $action is not yet known");
		  # this action not known, just add
		  $changes ++;
		  push @syslogcontents, "$facility.$priority\t$action\n";
	      }
	  }
	  # next selector
	  $selectors ++;
	  $selectorpath = "$configpath/selector/$selectors";
      }
      if ( $fullcontrol ){
	  push @syslogcontents, "$line\t$action\n";
      }
      # next entry;
      $entry ++;
      $configpath     = ${basepath}."/config/$entry";
  }
  if ( $fullcontrol ){
      open SLC, "+>$syslogconf.new";
      print SLC @directives;
      print SLC @syslogcontents;
      close SLC;
      $changes = system ("/usr/bin/diff", "-q", "$syslogconf.new", "$syslogconf"); 
      if ( $changes ){
          $self->debug(2,"there are changes to be made to $syslogconf");
          my $rc = system("/bin/mv", "$syslogconf.new", "$syslogconf");
      }
  }
  elsif ($changes){
      open SLC, "+>$syslogconf";
      print SLC @directives;
      print SLC @syslogcontents;
      close SLC;
  };

# now the options for the daemons
  $syslogconf = "/etc/sysconfig/$daemontype";
  $basepath = "/software/components/syslog/syslogdoptions";
  if ($config->elementExists($basepath)) {
    my $options = $config->getValue($basepath);
    $changes+=NCM::Check::lines($syslogconf,
                  linere => "^\\s*SYSLOGD_OPTIONS.*",
                  goodre => "^\\s*SYSLOGD_OPTIONS\\s*=\\s*\"$options\"",
                  good   => "SYSLOGD_OPTIONS=\"$options\"" );
  }
  $basepath = "/software/components/syslog/klogdoptions";
  if ($config->elementExists($basepath)) {
    my $options = $config->getValue($basepath);
    $changes+=NCM::Check::lines($syslogconf,
                  linere => "^\\s*KLOGD_OPTIONS.*",
                  goodre => "^\\s*KLOGD_OPTIONS\\s*=\\s*\"$options\"",
                  good   => "KLOGD_OPTIONS=\"$options\"" );
  }

  if ($changes){
    system("/sbin/service $daemontype restart");
  }

  return;
}
##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;
  $self->info("Unconfigure does nothing for $0\n");
  return;
}

sub KnownAction {
  my ($self,$action,@syslogcontents) = @_;
  # do not consider actions that appear in comment lines
    return  map { /^[^#].*\s$action/ } @syslogcontents;
}

sub KnownFacility {
  my ($self,$facility,$action,@syslogcontents) = @_;
# the facility may alreay start at column1, so I can not use "^[^#]" to veto comments
      return map { /^.*${facility}\..*\s+${action}/ } @syslogcontents;
}

1; #required for Perl modules
