# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::pine;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use NCM::Check;

use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

my @cfgfiles=('/etc/pine.conf', '/etc/alpine/pine.conf');
my $mypath='/software/components/pine'; 


sub mySubst {
  my ($cfgfile,$key,$value,$nobackup)=@_;

  return NCM::Check::lines($cfgfile,
	linere => $key.'\s*=.*',
	goodre => $key.'='.quotemeta($value),
	good   => $key.'='.$value,
	keep   => 'first',
	add    => 'last',
	backup => ($nobackup?undef:'.old'));

}

##########################################################################
sub Configure {
##########################################################################
  my ($self,$config)=@_;
  my $value="";
  my $userdomain="unknown domain";
  my $ret=0;

  for my $cfgfile (@cfgfiles) {

      # need to create the directory tree and file for NCM::Check?
      if (! -r $cfgfile ) {
	  if(!$NoAction) {
	      my $fullpath='';
	      for my $dir (split ('/', $cfgfile)) {
		  next unless($dir); # empty match on leading /
		  $fullpath .= '/'.$dir;
		  $self->debug(5, "looking at $fullpath");
		  next if ( -d $fullpath);
		  last if ($fullpath eq $cfgfile);
		  if (! mkdir ($fullpath)) {
		      $self->error("couldn't create directory $fullpath: $!");
		      return 0;
		  } else {
		      $self->info("created directory $fullpath");
		  }
	      }
	      if(!open(FD, ">$cfgfile")) {
		  $self->error("couldn't create $cfgfile: $!");
		  return 0;
	      }
	      if(!print FD <<EOFpine) {
# system-wide pine/alpine config file
#    created by ncm-pine
# manual changes may get (partly) overwritten
EOFpine
                  $self->error("couldn't write to $cfgfile: $!");
                  return 0;
              }
	      if(!close(FD)) {
		  $self->warn("couldn't close $cfgfile: $!");
	      }
	      $self->info("created missing $cfgfile");
	  } else {
	      $self->info("would need to create $cfgfile");
	  }
      } else {
	  $self->debug(1, "found existing $cfgfile");
      }

      if($config->elementExists($mypath."/userdomain")) {
	$userdomain=$config->getValue($mypath."/userdomain");
	$ret+=mySubst($cfgfile,'user-domain',$userdomain,0);
      }
      if($config->elementExists($mypath."/smtpserver")) {
	$ret+=mySubst($cfgfile,'smtp-server',$config->getValue($mypath."/smtpserver"),1);
      }
      if($config->elementExists($mypath."/nntpserver")) {
	$ret+=mySubst($cfgfile,'nntp-server',$config->getValue($mypath."/nntpserver"),1);
      }
      if($config->elementExists($mypath."/inboxpath")) {
	$ret+=mySubst($cfgfile,'inbox-path',$config->getValue($mypath."/inboxpath"),1);
      }
      if($config->elementExists($mypath."/foldercollection")) {
	$ret+=mySubst($cfgfile,'folder-collections',$config->getValue($mypath."/foldercollection"),1);
      }
      if($config->elementExists($mypath."/ldapserver")) {
	$ret+=mySubst($cfgfile,'ldap-servers',$config->getValue($mypath."/ldapservers"),1);
      }
      if($config->elementExists($mypath."/ldapnameattr")) {
	$ret+=mySubst($cfgfile,'name-attribute',$config->getValue($mypath."/ldapnameattr"),1);
      }
      if($config->elementExists($mypath."/disableauth")) {
	$ret+=mySubst($cfgfile,'disable-these-authenticators',$config->getValue($mypath."/disableauth"),1);
      }
  }
  $self->OK("Configured pine for $userdomain") if ($ret);
  return;
}


##########################################################################
sub Unconfigure {
##########################################################################
    my ($self,$config)=@_;
    my $ret=0;
    unless ($NoAction) {

	for my $cfgfile (@cfgfiles) {
	    next if (! -e $cfgfile);

	    $ret+=mySubst($cfgfile,'user-domain',' ',0);
	    $ret+=mySubst($cfgfile,'smtp-server',' ',1);
	    $ret+=mySubst($cfgfile,'nntp-server',' ',1);
	    $ret+=mySubst($cfgfile,'inbox-path',' ',1);
	    $ret+=mySubst($cfgfile,'folder-collections',' ',1);
	    $ret+=mySubst($cfgfile,'ldap-servers',' ',1);
	    $ret+=mySubst($cfgfile,'name-attribute',' ',1);
	    $ret+=mySubst($cfgfile,'disable-these-authenticators',' ',1);
	}
    }
    $self->OK("Unconfigured pine for localhost") if ($ret);
    return; 
}
1; #required for Perl modules


### Local Variables: ///
### mode: perl ///
### End: ///
