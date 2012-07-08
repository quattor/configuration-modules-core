# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

package NCM::Component::afsclt;

#
# a few standard statements, mandatory for all components
#

use strict;
use NCM::Component;
use NCM::Check;
use LWP::Simple;

use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;

$NCM::Component::afsclt::NoActionSupported = 1;

# prevent authconfig from trying to launch in X11 mode
delete($ENV{"DISPLAY"});

#*** The following gives the OS name using the LC perl modules.
#*** In example, $OSname can be 'Linux' or 'Solaris'
#*** It's equivalent to perl's variable $^O (it gives the OS in lower-case)
use LC::Sysinfo;
my $OSname=LC::Sysinfo::os()->name;
my $authconfig='/usr/bin/authconfig';
my $iptables = '/etc/sysconfig/iptables';
my $sysconfig_afs = '/etc/sysconfig/afs';
my $afs_cacheinfo = '/usr/vice/etc/cacheinfo';
my $localcelldb = "/usr/vice/etc/CellServDB";

my $mypath='/software/components/afsclt'; # this could be rather in /system/filesystems/remote ?
my $compname = "NCM-afsclt";

#***    In Solaris the fs executable at /usr/afsws/bin
#*** so we put that directory first in the path.
if ($OSname=~ /Solaris/) {$ENV{'PATH'}="/usr/afsws/bin:$ENV{'PATH'}"}

sub authconfig_OK {
  my ($self,$authconfig)=@_;

  # This should be more elaborate 

  unless (-x $authconfig) {
    $self->error ("$authconfig not found");
    return 0;
  }
  return 1;
}

##########################################################################
sub Configure {
##########################################################################
#***    In Solaris authconfig is not used so Configure_Cell is
#*** not needed. The firewall is not enabled so we don't run 
#*** Configure_firewall. In addition, the afs configuration files are
#*** not updated from the CDB so we don't use Configure_Config.
   my ($self,$config)=@_;
   if ($OSname=~ /Linux/) {
      $self->Configure_PAM($config);
      $self->Configure_Cell($config);
      $self->Configure_firewall($config);
      $self->Configure_Config($config);
  }
  $self->Configure_Cache($config);
  $self->Configure_CellServDB($config);
}

##########################################################################
sub Unconfigure {
##########################################################################
  my ($self,$config)=@_;
  $self->Unconfigure_Cache($config);
  if ($OSname=~ /Linux/) {
      $self->Unconfigure_Config($config);
      $self->Unconfigure_firewall($config);
      $self->Unconfigure_Cell($config);
  }
}

##########################################################################
sub Configure_Cell {
##########################################################################
  my ($self,$config)=@_;
  my $thiscell = "/usr/vice/etc/ThisCell";
  my $current_cell;
  unless ($config->elementExists($mypath."/thiscell")) {
    $self->error("cannot get $mypath/thiscell");
    return;
  }

  my $afscell=$config->getValue($mypath."/thiscell");

  if (open(THISCELL, "<", $thiscell)) {
    $current_cell = <THISCELL>;
    close(THISCELL);
    chomp($current_cell);
  } else {
    $self->warn("cannot read $thiscell: $!");
  }

  if ($current_cell && $current_cell eq $afscell) {
    $self->info("actual cell '$current_cell' in $thiscell is OK");
  } elsif (! $NoAction) {
    if ($current_cell) {
      $self->info("replacing '$current_cell' with '$afscell' in $thiscell");
    }
    unless (open(THISCELL, ">", $thiscell)) {
      $self->error("cannot write $thiscell: $!");
      return;
    }
    print THISCELL $afscell."\n";
    close(THISCELL);

    $self->OK("Configured AFS client for cell $afscell in $thiscell");
  } else {
    $self->info("would need to update $thiscell\n");
  }

  return;
}

##########################################################################
sub Configure_PAM ( $$ ) {
##########################################################################
  my ($self,$config)=@_;
  my $libpam;
  my $libpam_options_auth;       # system_auth session/password/whatever section
  my $libpam_options_auth_auth;
  my $libpam_options_auth_session;
  my $libpam_options_auth_passwd;
  my $libpam_options_refresh;    # screensavers and such, all sections
  my $ret = 0;

  if ($config->elementExists($mypath."/libpam")) {
    $libpam=$config->getValue($mypath."/libpam");
  }
  if(! $libpam) {  # not set, or set to ''
    $self->info("no $mypath/libpam specified, not doing anything to PAM config");
    return 0;
  }


  if ($config->elementExists($mypath."/libpam_options_auth")) {
    $libpam_options_auth=$config->getValue($mypath."/libpam_options_auth");
  } else {
    $self->info("no explicit $mypath/libpam_options_auth, using default");
  }
  if ($config->elementExists($mypath."/libpam_options_auth_auth")) {
    $libpam_options_auth_auth=$config->getValue($mypath."/libpam_options_auth_auth");
  } else {
    $self->info("no explicit $mypath/libpam_options_auth_auth, using default");
  }
  if ($config->elementExists($mypath."/libpam_options_auth_session")) {
    $libpam_options_auth_session=$config->getValue($mypath."/libpam_options_auth_session");
  } else {
    $self->info("no explicit $mypath/libpam_options_auth_session, using default");
  }
  if ($config->elementExists($mypath."/libpam_options_auth_passwd")) {
    $libpam_options_auth_passwd=$config->getValue($mypath."/libpam_options_auth_passwd");
  } else {
    $self->info("no explicit $mypath/libpam_options_auth_passwd, using default");
  }

  if ($config->elementExists($mypath."/libpam_options_refresh")) {
    $libpam_options_refresh=$config->getValue($mypath."/libpam_options_refresh");
  } else {
    $self->info("no explicit $mypath/libpam_options_refresh, using default");
  }

  # Authentication: Funnily enough, we actually configure Kerberos authentication here (not "AFS").
  # we no longer use authconfig on Linux but manipulate the config file directly, similar on Solaris.

  if ($OSname =~ /Solaris/) {
    $self->warn("Somebody needs to write something to configure PAM on Solaris"); #FIXME
    return 0;

    $libpam='/usr/lib/security/pam_afs.so.1' unless ($libpam); # openafs flavour
    $libpam_options_auth = "try_first_pass ignore_root setenv_password_expires" unless ($libpam_options_auth);
    $libpam_options_auth_auth = "$libpam_options_auth" unless ($libpam_options_auth_auth);
    $libpam_options_auth_session = "$libpam_options_auth" unless ($libpam_options_auth_session);
    $libpam_options_auth_passwd = "$libpam_options_auth" unless ($libpam_options_auth_passwd);
    $libpam_options_refresh = "try_first_pass ignore_root refresh_token" unless ($libpam_options_refresh);

    my $pam_config = '/etc/pam.conf';

    if(! -e "$libpam") {
      $self->warn("Cannot find $libpam, will not configure PAM");
      return 0;
    }

    if ( ! -e "$pam_config") {
      $self->warn("Cannot find $pam_config - not touching it");
    } else {
      $ret = LC::Check::file($pam_config,
			     backup => '.ncm_orig',
			     source => $pam_config,
			     code => sub {  # gets actual, returns expected.
				    my $actual = shift;
				    $self->debug(5, "$pam_config is now:\n$actual");
				    my @actual = split (/\n/, $actual);
				    my @expected = grep { $_ !~
							   /(added by $compname|pam_afs|pam_krb5|pam_heimdal)/
							 } @actual; # remove other AFS/Krb PAMs
				    @expected = map {
				      # add our lib after pam_unix, slightly different file format
				      if ($_ =~ /^(\S+)(\s+)(auth)(\s+)(\S+)(\s+)\S*pam_unix/) {
					($_, "# next line added by $compname", "$1$2$3$4$5$6$libpam\t$libpam_options_auth_auth");
				      } elsif ($_ =~ /^(\S+)(\s+)(session)(\s+)(\S+)(\s+)\S*pam_unix/) {
					($_, "# next line added by $compname", "$1$2$3$4$5$6$libpam\t$libpam_options_auth_session");
				      } elsif ($_ =~ /^(\S+)(\s+)(password)(\s+)(\S+)(\s+)\S*pam_unix/) {
					($_, "# next line added by $compname", "$1$2$3$4$5$6$libpam\t$libpam_options_auth_passwd");
				      } else {
					$_;
				      }
				    } @expected;
				    my $expected = join("\n",@expected)."\n";
				    $self->debug(5, "$pam_config will be:\n$expected");
				    return $expected;
				   }
			  );
    }


  } elsif ($OSname =~ /Linux/) {

    ## pam_krb5  (Default)
    $libpam='/lib/security/$ISA/pam_krb5afs.so' unless ($libpam); # do _NOT_ evaluate the $ISA
    $libpam_options_auth = "try_first_pass external=sshd minimum_uid=100" unless ($libpam_options_auth);
    $libpam_options_auth_auth = "$libpam_options_auth" unless ($libpam_options_auth_auth);
    $libpam_options_auth_session = "$libpam_options_auth" unless ($libpam_options_auth_session);
    $libpam_options_auth_passwd = "$libpam_options_auth" unless ($libpam_options_auth_passwd);


    ## OpenAFS
    #$libpam='/lib/security/$ISA/pam_afs.krb.so' unless ($libpam);
    #$libpam_options_auth = "try_first_pass ignore_root setenv_password_expires";
    #$libpam_options_refresh = "try_first_pass ignore_root refresh_token";

    # safety catch - avoid configuring a non-existing PAM library
    my $ISA = '';
    my $HWname = LC::Sysinfo::uname()->machine;
    if ($HWname =~ /x86_64/) {
      $ISA = '../../lib64/security';
    }
    my $libpamtmp = $libpam;
    $libpamtmp =~ s:^(.*)\$ISA/(.*):$1$ISA/$2:;
    if(! -e "$libpamtmp") {
      $self->warn("Cannot find $libpam (=$libpamtmp), will not configure PAM");
      return 0;
    }

    my $pam_systemauth = "/etc/pam.d/system-auth";
    my $pam_screensaver = '/etc/pam.d/screensaver-auth'; #optional

    if ( ! -e "$pam_systemauth") {
      $self->warn("Cannot find $pam_systemauth - not touching it");
    } else {
      $ret = LC::Check::file($pam_systemauth,
			     backup => '.ncm_orig',
			     source => $pam_systemauth,
			     code => sub {  # gets actual, returns expected.
				    my $actual = shift;
				    $self->debug(4, "$pam_systemauth is now:\n$actual");
				    my @actual = split (/\n/, $actual);
				    my @expected = grep { $_ !~
							   /(added by $compname|pam_afs|pam_krb5afs|pam_heimdal)/
							 } @actual; # remove other AFS/Krb PAMs
				    @expected = map {
				      # add our lib after pam_unix
				      if ($_ =~ /^(auth) (\s*)(\S+) (\s*)\S*pam_unix/) {
					($_, "# next line added by $compname", "$1 $2$3 $4$libpam $libpam_options_auth_auth");
				      } elsif ($_ =~ /^(session) (\s*)(\S+)(\s+)\S*pam_unix/) {
					($_, "# next line added by $compname", "$1 $2$3 $4$libpam $libpam_options_auth_session");
				      } elsif ($_ =~ /^(password) (\s*)(\S+)(\s+)\S*pam_unix/) {
					($_, "# next line added by $compname", "$1 $2$3 $4$libpam $libpam_options_auth_passwd");
				      } else {
					$self->debug(5, "ignoring PAM line $_");
					$_;
				      }
				    } @expected;
				    my $expected = join("\n",@expected)."\n";
				    $self->debug(4, "$pam_systemauth will be:\n$expected");
				    return $expected;
				   }
			  );
    }

    # a special PAM file for screensavers isn't always required
    # silently ignore it if missing and we have no special options to set
    if (! -e "$pam_screensaver") {
      if (! $libpam_options_refresh ) {
         $self->debug(1, "No $pam_screensaver and no special options for it, ignoring");
      } else {
         $self->warn("No $pam_screensaver but have libpam_options_refresh set - cannot configure!");
      }
    } else {
      $libpam_options_refresh = "try_first_pass" unless ($libpam_options_refresh);

      $ret = LC::Check::file($pam_screensaver,
			     backup => '.ncm_orig',
			     source => $pam_screensaver,
			     code => sub {  # gets actual, returns expected.
				    my $actual = shift;
				    $self->debug(5, "$pam_screensaver is now:\n$actual");
				    my @actual = split (/\n/, $actual);
				    my @expected = grep { $_ !~
							   /(added by $compname|pam_afs|pam_krb5afs|pam_heimdal)/
							 } @actual; # remove other AFS/Krb PAMs
				    @expected = map {
				      if ($_ =~ /^(\S+)(\s+)(\S+)(\s+)\S+pam_unix/) {
					($_, "# next line added by $compname", "$1$2$3$4$libpam\t$libpam_options_refresh"); # add our lib after pam_unix
				      } else {
					$_;
				      }
				    } @expected;
				    my $expected = join("\n",@expected)."\n";
				    $self->debug(5, "$pam_screensaver will be:\n$expected");
				    return $expected;
				   }
			  );
    }
  } else {
    # non-Linux / non-Solaris
    $self->error("Don't know how to configure PAM on $OSname");
    return 0;
  }

  return $ret;
}


##########################################################################
sub Configure_firewall ( $$ ) {
##########################################################################
  my ($self,$config)=@_;

  if (! open(FD, "<$iptables")) {
    $self->info("iptables will not be configured: error opening file $iptables: $!");
    return 0;
  }

  my @iptables = <FD>;
  close(FD);
  my @newtables;
  my $added = 0;
  my $found_rh_area = 0;
  my $return = 1;

  my $afsrules = <<EOFtable;
# AFS client rules to enable server callbacks ,added by $compname
-A RH-Firewall-1-INPUT -m state --state NEW -m udp -p udp --dport 7001 -j ACCEPT
-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 7002 -j ACCEPT
-A RH-Firewall-1-INPUT -m state --state NEW -m udp -p udp --dport 7003 -j ACCEPT
-A RH-Firewall-1-INPUT -m state --state NEW -m udp -p udp --dport 7004 -j ACCEPT
EOFtable

  # add to RH customizations area before first non-ACCEPT

  if (grep (/-p\s+udp.*--dport\s+7001/, @iptables)) {
    # be happy.
    $self->info("AFS callback port is already open");

  } else {
    # add missing lines.
    foreach my $line (@iptables) {
      $self->debug(5, "found line $line");

      if ($line =~ /^-A RH-Firewall-1-INPUT/ ) {
	$self->debug(3, "found start of RH config area");
	$found_rh_area = 1;
      }
      if (! $added &&
          $found_rh_area &&
          $line !~ /^(#|-A RH-Firewall-1-INPUT.*-j\s*ACCEPT)/ ) {
	# we are running past the right spot!
	$self->debug(3, "running past the the right spot, adding our rules now");
	push(@newtables, $afsrules);
	$added =1; # pretend we have seen the lines
	$self->info("added AFS callback ports to $iptables");
      }

      $self->debug(3, "copying existing line");
      push(@newtables, $line);
    }

    if ($added) {
      my $newtables = join('',@newtables);

      $self->debug(3, "new $iptables:\n".$newtables);
      $return = (LC::Check::file($iptables,
			     "contents"    => $newtables
			    )
	    );
    }

  }

  return $return;
}


##########################################################################
sub Configure_Config {
##########################################################################
  my ($self,$config)=@_;

# bla. Only set interesting stuff right now -> OPTIONS, -nosettime, verbose, enabled

  my $node;
  my $options = '';
  my $have_config = 0;
  my $ret =1 ;
  if($config->elementExists("$mypath/options")) {
    $node = $config->getElement("$mypath/options");
    while ($node->hasNextElement()) {
      my $next = $node->getNextElement();
      my $nextname = $next->getName();
      my $nextvalue = $next->getValue();
      $options .= " " if $options;
      $options .= "-$nextname $nextvalue";
      $have_config = 1;
    }
  }
  # "settime" option
  if($config->elementExists("$mypath/settime")) {
    $node = $config->getElement("$mypath/settime");
    $have_config = 1;
    my $settime = $node->getValue();
    if(! $settime) {  # caution, not set = assume NTP
      $options .= " " if $options;
      $options .= "-nosettime"
    }
  }
  if($have_config) {
    $ret = NCM::Check::lines($sysconfig_afs,
			     linere => '^#.*$compname-options|OPTIONS=.*',
			     goodre => '^#.*$compname-options|OPTIONS=\s*"'.quotemeta($options).'"',
			     good   => "# changed by $compname-options\nOPTIONS=\"".$options."\"",
			     keep   => 'first',
			     add    => 'last',
			     backup => '.old_options');
  } else {
    $self->info("no OPTIONS configuration for $sysconfig_afs, skipping");
  }

  # cache size is configured in a separate function

  if($config->elementExists("$mypath/verbose")) {
    $node = $config->getElement("$mypath/verbose");
    my $verbose = $node->getValue() ? '-verbose' : '';
    $ret &= NCM::Check::lines($sysconfig_afs,
			     linere => '^#.*$compname-verbose|VERBOSE=.*',
			     goodre => '^#.*$compname-verbose|VERBOSE=\s*'.quotemeta($verbose),
			     good   => "# changed by $compname-verbose\nVERBOSE=".$verbose,
			     keep   => 'first',
			     add    => 'last',
			     backup => '.old_verbose');
  }

  if($config->elementExists("$mypath/enabled")) {
    $node = $config->getElement("$mypath/enabled");
    my $enabled = $node->getValue(); #syntax needs to be on/off, not yes/no
    if ($enabled =~ /^off$|^no$/i) {
      $enabled = 'off';
    } else {
      $enabled = 'on'; #default
    }

    $ret &= NCM::Check::lines($sysconfig_afs,
			     linere => '^#.*$compname-enabled|AFS_CLIENT=.*',
			     goodre => '^#.*$compname-enabled|AFS_CLIENT=\s*'.quotemeta($enabled),
			     good   => "# changed by $compname-enabled\nAFS_CLIENT=".$enabled,
			     keep   => 'first',
			     add    => 'last',
			     backup => '.old_enabled');
  }

  if($config->elementExists($mypath."/afsmount")) {
    my $new_afsmount = $config->getValue($mypath."/afsmount");
    if ($new_afsmount ne '/afs') {
      $self->error("cannot handle non-/afs AFS mount point $new_afsmount");
      return 0;
    }
  }

  return $ret;
}

##########################################################################
sub Configure_Cache {
##########################################################################
  my ($self,$config)=@_;

  my $run_cache = 0;  # how much cache the AFS kernel module believes it now has
  my $file_cache = 0; # how much cache is actually configured now in the config file
  my $file_cachemount = '';  # where should the cache be mounted per config file
  my $new_cache = 0;  # in 1k blocks.
  my $new_cachemount = '';
  my $automatic_cache = 0;

  my $ret = 1;

  if ($config->elementExists($mypath."/cachesize")) {
    $new_cache = $config->getValue($mypath."/cachesize");  #new cache size
  } else {
    $self->warn("cannot get CDB $mypath/cachesize, giving up");
    return;
  }

  if ($config->elementExists($mypath."/cachemount")) {
    my $cdb_cachemount=$config->getValue($mypath."/cachemount"); # new cache mount, if any
    if ( $cdb_cachemount =~ m;^(/[.\w\/-]+)$; ) {
      $new_cachemount=$1;
    } else {
      $self->warn("CDB new AFS cache mount point $cdb_cachemount looks weird");
    }
  }

  my $fs_run_cache_string =`fs getcacheparms 2>/dev/null`;
  if ($fs_run_cache_string
      =~ /AFS using \d+ of the cache's available (\d+) (\w+) byte blocks/){
    if($2 ne "1K") {
      $self->error("cannot handle $2 (non-1K) AFS cache block sizes");
      return 0;
    }
    $run_cache = $1;
  } else {
    $self->info("cannot determine current AFS cache size, changing only config file");
  }


  if (! open(CI, '<'.$afs_cacheinfo)) {
    $self->warn("cannot read current AFS cachesize from $afs_cacheinfo: $!");
    return 0;
  }
  my @t = <CI>;
  close(CI);
  if ($t[0] =~ m;^([^:]+):([^:]+):(\d+)$; ) {
    my $afsmount = $1;
    $file_cachemount = $2;
    $file_cache = $3;
    if($afsmount ne "/afs") {
      $self->error("cannot handle non-/afs mount point $afsmount in $afs_cacheinfo: ".$t[0]);
      return 0;
    }
  } else {
    $self->error("cannot parse stored AFS cache mount or size from $afs_cacheinfo: ".$t[0]);
    return 0;
  }

  if(! $new_cachemount) {
    $new_cachemount = $file_cachemount;
  } else {
    # all kinds of satey test for new cache mount point here
    if (! -d $new_cachemount ) {
      $self->warn("new AFS cache mount $new_cachemount is not a directory, ignoring");
      $new_cachemount = $file_cachemount;
    }
  }

  if ($new_cachemount && $file_cachemount ne $new_cachemount) {
    $self->warn("cannot yet handle AFS cache mount move $file_cachemount -> $new_cachemount");
  }

  # Linux AFS client can autoconfigure if the AFS cache is on a
  # separate partition (and we then won't change the other config
  # files/run-time cache). Other machines with a separate partition
  # will use 85% as cache size (heuristic, cache manager says 90%).
  # Machines without a separate partition get the requested size.

  # Please note that you cannot force a smaller cache if running with
  # separate cache partition (forcing a larger one wouldn't make any sense)
  my $dfout;
  if (LC::Process::execute(['df', '-k', $new_cachemount],
                           "stdout" => \$dfout,
			   "stderr" => "stdout"
			  ) ) {
    my @df = split('\n', $dfout);

    my @mount = grep { m{$new_cachemount} } @df;
    if ($#mount >=0 && $mount[0] =~ m{^(.*?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(.*)}) {
      $automatic_cache = 1;
      my $real_cachedev = $1;
      my $real_cachesize = $2;
      my $real_cachemount = $6;
      $new_cache = 0.85 * $real_cachesize;  # heuristic here
      $self->info("found AFS cache partition on $real_cachedev, ".$real_cachesize."k");
    } else {
      $self->debug(2, "AFS cache $new_cachemount is not on a separate partition");
    }
  } else {
    $self->warn("cannot run 'df' on the AFS cache?");
  }

  # OpenAFS-1.4/Linux takes the info from /etc/sysconfig/afs
  if( -r $sysconfig_afs) {
    if($automatic_cache) {
      $new_cache = "AUTOMATIC";
    }
    $ret &= NCM::Check::lines($sysconfig_afs,
			    linere => '^#.*$compname-cachesize|CACHESIZE=.*',
			    goodre => '^#.*$compname-cachesize|CACHESIZE=\s*'.quotemeta($new_cache),
			    good   => "# changed by $compname-cachesize\nCACHESIZE=".$new_cache,
			    keep   => 'first',
			    add    => 'last',
			    backup => '.old_verbose');

  }

  # adjust stored cache size (gets overwritten on restart for OpenAFS-1.4)
  if ($new_cache ne "AUTOMATIC") {
    if ($new_cache != $file_cache) {
      if(! open (CI, '>'.$afs_cacheinfo)) {
	$self->error("cannot open $afs_cacheinfo for writing: $!");
	return 0;
      }
      print CI "/afs:$file_cachemount:$new_cache\n";
      close(CI) or
	$self->warn("cannot close $file_cachemount: $!");
      $self->OK("changed AFS cache config file $afs_cacheinfo: $file_cachemount $run_cache -> $new_cache (1K blocks)");
    } else {
      $self->info("AFS cache size is unchanged ($new_cache K)");
    }
  } else {
    $self->info("AFS cache on separate partition, not changed");
  }

  # adjust online (in-kernel) value
  if($run_cache && ($new_cache ne "AUTOMATIC") && ($run_cache != $new_cache)) {
    my $fscommand = "fs setcachesize $new_cache";
    my $fsout=`$fscommand 2>&1`;
    if ($? >> 8) {
      $self->warn("problem changing running AFS cache size via \"$fscommand\":\n$fsout");
    } else {
      $self->OK("changed running AFS cache $run_cache -> $new_cache (1K blocks)");
    }
  }

  return $ret;
}


##########################################################################
# This code comes from sue/feature/afs/update.pl, slightly modified
#
sub Configure_CellServDB {
##########################################################################
  my ($self,$config)=@_;
  my $master_cellservdb_cdb;
  my $master_cellservdb;  # need to "sanitize" for perl-taint
  no locale;  # to be able to rely on \w

  if ($config->elementExists($mypath."/cellservdb")) {
    $master_cellservdb_cdb = $config->getValue($mypath."/cellservdb");

    if ( $master_cellservdb_cdb =~ m;^(file://)?(\/[\w\/.-]+);i) { # absolute file name, alphanum, slashes, -, _
      if ( -r "$2" ) {
	$master_cellservdb = "file://$2";
      } else {
	$self->warn("cannot access cellservdb $2, giving up");
	return 0;
      }
    } elsif ( $master_cellservdb_cdb =~ m;^((ftp|http|file)://.+);i) { # known URIs - could contain other stuff i.e. for programmatic access
      $master_cellservdb = $1;
    } else {
      $self->warn("weird/unsafe cellservdb URL/PATH: $master_cellservdb, giving up");
      return 0;
    }
  } else {
    $self->warn("cannot get CDB entry $mypath/cellservdb, cannot keep CellServDB updated");
    return 0;
  }
  # LWP::Simple means  no error messages etc.
  $self->info("will get cellservdb information from $master_cellservdb");

  # FIXME: UGLY HACK here - it appears that one can not "untaint" the
  # location variable via the above, any reference to $1 and such still leaves
  # it somehow tainted. Only explicit assignment seems to remove this.
  # The below is supposed to "cure" the following messages on SLC4, perl-5.8.8-10.el5_0.2, perl-libwww-perl-5.79-5
  ## Insecure dependency in connect while running with -t switch at /usr/lib/perl5/5.8.8/i386-linux-thread-multi/IO/Socket.pm line 114.
  ## Insecure dependency in connect while running with -t switch at /usr/lib/perl5/5.8.8/i386-linux-thread-multi/IO/Socket.pm line 120.

  my $ugly_hack;
  if ($master_cellservdb =~ m;(http://consult.cern.ch/service/afs/CellServDB);) {
      $ugly_hack = 'http://consult.cern.ch/service/afs/CellServDB';
      $master_cellservdb = $ugly_hack;
  }
  # end of UGLY HACK.

  my $cellservdb_content = LWP::Simple::get($master_cellservdb);
  if (! $cellservdb_content) {
    $self->info("cannot read cellservdb $master_cellservdb, AFS cell info not changed");
    return 1;
  }

  if ($NoAction) {
    $self->info("skipping CellServDB check and in-kernel update");
  } else {
    LC::Check::file("CellServDB",
		    "contents"    => $cellservdb_content,
		    "destination" => $localcelldb,
		    "owner"       => 0,
		    "mode"        => 0444,
		   );
    $self->update_afs_cells();
  }

  return 1;
}

# This code comes from sue/feature/afs/update.pl, slightly modified
# to work in our context (replace afsutil with "fs")
#
# update the list of known AFS cells and run "fs newcell" when needed
# This will only add new cells, not remove currently known ones.
#
sub update_afs_cells ( $$ ) {
    my($self) = @_;
    my($cell, %seen, %ipaddrs, @hosts, $todo, @todo, $error, $afsutil);
    local(*FH, $_);
    # init

    # read CellServDB
    # take it from the real file
    if( ! open(*FH, $localcelldb)) {
      $self->warn("cannot read local $localcelldb, giving up");
      return 0;
    }

    while (<FH>) {
        if (/^>(.\S+)/) {
            # new cell
            $cell = $1;
            $ipaddrs{$cell} = [];
        } elsif (/^(\S+)\s+\#\s*(\S+)/) {
            # new entry
            push(@{$ipaddrs{$cell}}, $1);
        }
    }
    close(FH);
    foreach $cell (keys(%ipaddrs)) {
        @{$ipaddrs{$cell}} = sort(@{$ipaddrs{$cell}});
        $self->Debug("CellServDB $cell -> @{$ipaddrs{$cell}}");
    }
    # read known cells
    @todo = ();
    my @current = `fs listcell -numeric 2>&1`;

    if($? >> 8 ) {
      $self->info("cannot read current AFS cell info via fs:\n".join('',@current));
      return 1;
    }
    foreach (@current) {
        chomp($_);
        next unless /^Cell\s+(\S+)\s+on hosts\s+(\S.+)\.$/;
        $cell = $1;
        @hosts = split(/\s+/, $2);
        $seen{$cell} = 1;
        $self->Debug("fs listcell: $cell -> @hosts");
        next unless $ipaddrs{$cell} && @{$ipaddrs{$cell}};
        @hosts = sort(@hosts);
        if ("@hosts" ne "@{$ipaddrs{$cell}}") {
            push(@todo, $cell);
            $self->Debug("cell info for $cell changed from @hosts to @{$ipaddrs{$cell}}");
        }
    }
    # check new cells
    foreach $cell (keys(%ipaddrs)) {
        next if $seen{$cell};
        next unless @{$ipaddrs{$cell}};
        push(@todo, $cell);
        $self->info("new cell $cell with @{$ipaddrs{$cell}}");
    }

    if (@todo) {
        $error = 0;
        foreach $cell (@todo) {
            my $out=`fs newcell $cell @{$ipaddrs{$cell}} 2>&1`;
	    if($? >> 8) {
	      $self->Debug("error while updating AFS cell info for $cell: $out");
	      $error++;
	    }
        }
	if ($error) {
	  $self->error("$error errors while updating AFS cell info for @todo");
	} else {
	  $self->OK("updated cell information for @todo", $error);
	}
    } else {
        $self->info("nothing to do for AFS cell information");
    }
    return !$error;
}

##########################################################################
sub Unconfigure_Cell {
##########################################################################
  unless ($NoAction) {
   my ($self,$config)=@_;

   return unless authconfig_OK($self,$authconfig);

  $self->warn("Unconfigure_Cell does not work for now (authconfig broken)");
  return;

   my $comm=$authconfig . " --nostart --kickstart --disableafs";
   my $s=`$comm`;
    if ($? >> 8) {
      $self->error("can't run $s, no changes made");
      return;
    }
    $self->OK("Unconfigured AFS client");
  }
  return; 
}

##########################################################################
sub Unconfigure_firewall {
##########################################################################
  my ($self,$config)=@_;

  if (! open(FD, "<$iptables")) {
    $self->info("iptables will not be unconfigured: error opening file $iptables: $!");
    return 0;
  }

  my @iptables = <FD>;
  close(FD);
  my @newtables;
  my $return = 1;
  my $found = 0;


  foreach my $line (@iptables) {
    $self->debug(5, "found line $line");

    if ($line =~ /^#.*$compname/ ||
	$line =~ /-p\s+udp.*--dport\s+7001/ ||
	$line =~ /-p\s+tcp.*--dport\s+7002/ ||
	$line =~ /-p\s+udp.*--dport\s+7003/ ||
	$line =~ /-p\s+udp.*--dport\s+7004/ ) {
      $self->debug(2, "skipping line with AFS ports");
      $found =1;
      next;
    }

    $self->debug(2, "copying existing line");
    push(@newtables, $line);

  }
  if ($found) {
    my $newtables = join('',@newtables);

    $self->debug(3, "new $iptables:\n".$newtables);
    $return = (LC::Check::file($iptables,
			       "contents"    => $newtables
			      )
	      );
  }
  return $return;
}


##########################################################################
sub Unconfigure_Config {
##########################################################################
  my ($self,$config)=@_;

  if (! open(FD, "<$sysconfig_afs")) {
    $self->error("Cannot unconfigure: error opening file $sysconfig_afs: $!");
    return 0;
  }
  my @sysconfig = <FD>;
  close (FD);
  my @newconfig;
  my $return = 1;
  my $found = 0;

  foreach my $line (@sysconfig) {
    $self->debug(5, "found line $line");

    if ($line =~ /^#.*$compname/ ) {
      $self->debug(2, "removing NCM comment line");
      $found =1;
      next; # just skip
    } elsif ($line =~ /^OPTIONS=/ ) {
      $self->debug(2, "resetting OPTIONS");
      $line = "OPTIONS=\$MEDIUM\n";
      $found =1;
    } elsif ($line =~ /^VERBOSE=/ ) {
      $self->debug(2, "resetting VERBOSE");
      $line = "VERBOSE=\n";
      $found =1;
    } elsif ($line =~ /^AFS_CLIENT=/ ) {
      $self->debug(2, "resetting AFS_CLIENT enable");
      $line = "AFS_CLIENT=on\n";
      $found =1;
    } else {
      $self->debug(2, "copying existing line");
    }
    push(@newconfig, $line);
  }

  if ($found) {
    my $newconfig = join('',@newconfig);

    $self->debug(3, "new $sysconfig_afs:\n".$newconfig);
    $return = (LC::Check::file($sysconfig_afs,
			       "contents"    => $newconfig
			      )
	      );
  }
  return $return;
}

##########################################################################
sub Unconfigure_Cache {
##########################################################################
  my ($self,$config)=@_;
  $self->info("AFS cache config not changed");
  return 1;
}

##########################################################################
sub Unconfigure_PAM {
##########################################################################
  my ($self,$config)=@_;
  my $libpam;
  my $libpam_options_auth;
  my $libpam_options_refresh;
  my $ret = 0;

  if ($OSname =~ /Solaris/) {
    $self->warn("Somebody needs to write something to unconfigure PAM on Solaris"); #FIXME
    return 0;

    my $pam_config = '/etc/pam.conf';


  } elsif ($OSname =~ /Linux/) {

    my $pam_systemauth = "/etc/pam.d/system-auth";
    my $pam_screensaver = '/etc/pam.d/screensaver-auth';

    $ret = LC::Check::file($pam_systemauth,
			   backup => '.ncm_orig',
			   source => $pam_systemauth,
			   code => sub {  # gets actual, returns expected.
				    my $actual = shift;
				    my @actual = split (/\n/, $actual);
				    my @expected = grep { $_ !~
							   /(added by $compname|pam_afs|pam_krb5afs|pam_heimdal)/
							 } @actual; # remove other AFS/Krb PAMs
				    my $expected = join("\n",@expected)."\n";
				    $self->debug(5, "$pam_systemauth should be:\n$expected");
				    return $expected;
				   }
			  );

    $ret = LC::Check::file($pam_screensaver,
			   backup => '.ncm_orig',
			   source => $pam_screensaver,
			   code => sub {  # gets actual, returns expected.
				    my $actual = shift;
				    my @actual = split (/\n/, $actual);
				    my @expected = grep { $_ !~
							   /(added by $compname|pam_afs|pam_krb5afs|pam_heimdal)/
							 } @actual; # remove other AFS/Krb PAMs
				    my $expected = join("\n",@expected)."\n";
				    $self->debug(5, "$pam_screensaver should be:\n$expected");
				    return $expected;
				   }
			  );

  } else {
    $self->warn("Don't know how to unconfigure PAM on $OSname");
    return 0;
  }

  return $ret;


}


1; #required for Perl modules

### Local Variables: ///
### mode: perl ///
### End: ///
