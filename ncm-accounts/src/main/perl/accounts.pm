# ${license-info}
# ${developer-info}
# ${author-info}


package NCM::Component::accounts;

use strict;
use NCM::Component;
use vars qw(@ISA $EC);
@ISA = qw(NCM::Component);
$EC=LC::Exception::Context->new->will_store_all;
use NCM::Check;
use LC::Process qw (output execute);
use LC::File qw (makedir);
use EDG::WP4::CCM::Element;

use File::Basename;
use File::Path;

use File::Copy;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use User::pwent;

local(*DTA);

use constant { NAME    => "name",
               PASSWORD  => "password",
               UID     => "uid",
               GID     => "gid",
               QUOTA   => "quota",
               COMMENT => "comment",
               GCOS    => "gcos",
               HOMEDIR => "homedir",
               SHELL   => "shell",
               EXPIRE  => "expire",
               PGROUP  => "pgroup",
               GROUPS => "groups"
               };

#The programs that might change according if we use ldap or not
my $USERADD = "/usr/sbin/useradd";
my $USERMOD = "/usr/sbin/usermod";
my $USERDEL = "/usr/sbin/userdel";
my $GRPDEL = "/usr/sbin/groupdel";
my $GRPADD = "/usr/sbin/groupadd";
my $GRPMOD = "/usr/sbin/groupmod";
my $SYSID = "/usr/bin/id";



use constant { PWCONV  => "/usr/sbin/pwconv",
               PWUNCONV  => "/usr/sbin/pwunconv",
               GRPCONV  => "/usr/sbin/grpconv",
               GRPUNCONV  => "/usr/sbin/grpunconv",
               NEWUSERS => "/usr/sbin/newusers",
               CHPASSWD => "/usr/sbin/chpasswd"
         };

use constant {NEWPASSLIST => "/tmp/newpass.ncm-accounts",
              NEWUSERLIST => "/tmp/newusers.ncm-accounts"
              };


our %FLAGS = (
              PASSWORD, "-p", 
              UID, "-u", 
              PGROUP, "-g", 
              GROUPS, "-G",
              QUOTA, "", 
              COMMENT, "-c", 
              GCOS, "-c", 
              HOMEDIR, "-d", 
              SHELL, "-s", 
              EXPIRE, "-e"
              );

#If we should use ldap
my $useLdap = 0;

# For optimization
my %createdParents = ();

# Generates a list of options for usermod/useradd
# based on a hash parameter describing a user
# IN:  hash representing user
# OUT: list containing flags and values 
##########################################################################
sub generate_opts {
##########################################################################
    my $user = shift;
    my @opts;
    foreach my $field (sort keys %$user) {
        if (defined ($FLAGS{$field}) && (defined ($user->{$field}) &&  $user->{$field} ne "")) {
            push(@opts,$FLAGS{$field});

            if ($field eq GCOS) {
                push(@opts,quote_string($user->{$field}));
            } elsif ($field eq PASSWORD) {
                push(@opts, ("'" . $user->{$field} . "'"));
            } else {
                push(@opts,$user->{$field});
            }

        }
    }
    return @opts;
}

# Creates any intermediate directories missing for the home directory,
# fixing bug #50029. The final home directory is left for the
# useradd/usermod commands.
# Return value is:
#   - -1 if directory already existed
#   - 1 if the directory was succesfully created
#   - 0 if an error occured during directory creation
# Don't signal error in this function, let's the caller do it.

sub prepare_home {
    my ($self, $homedir) = @_;

    my @spl = split("/", $homedir);
    my $homeparent = join("/",  @spl[0 .. (scalar(@spl)-2)]);

    my $status;    
    if ( $createdParents{$homeparent} || -d $homeparent ) {
      $self->debug(2, "Home directory parent $homeparent already exists");   
      $status = -1;   
    } else {
      $self->debug(1, "Creating home directory parent $homeparent");   
      if ( makedir($homeparent,0755) ) {
        $status = 1;
      } else {
        $status = 0
      }
    }
    
    if ( $status ) {
      $createdParents{$homeparent} = 1    # Value is useless      
    }

    return ($status);
}

# Modifies an existing user using usermod, based on user hash. Has to
# be before add_user
# IN: self (for logging), user hash.  OUT:
##########################################################################
sub modify_user {
##########################################################################
    my ($self, $user, $createHome) = @_;
    
    my @opts=generate_opts($user);
    $self->verbose("Modifying user $user->{name}");
    if ($createHome) {
      push(@opts,"-m");
      $self->prepare_home($user->{homedir});
    }
    
    if($useLdap == 1){
      push(@opts,"-o");
    }

    # call usermod with generated options
    # unless (execute ([$USERMOD,@opts,$user->{"name"}])) {
    unless (execute ([($USERMOD.' '.join(' ', @opts)." ".$user->{"name"})])) {
      $self->warn("Failed to call ". $USERMOD);
      return;
    }
    
    if($?){
      $self->warn("Failed to modify user " . $user->{"name"});
    }
}

# Adds a user using useradd, generating options from a hash.
# IN:  self (to use logging), user hash, createHome flag
# OUT: 
##########################################################################
sub add_user {
##########################################################################
    my ($self, $user, $createHome) = @_;
    my $username=$user->{"name"};

    # If the home directory is defined and must be created, then ensure that the parent
    # directory exists (useradd will not create it).
    if (defined($user->{"homedir"})) {
        if ( $user->{"createHome"} ) {
          my $status = $self->prepare_home($user->{"homedir"});
          unless ( $status ) {
            $self->error("can't create home parent directory ".$user->{"homedir"}."; skipping user $username");
            return 1;            
          }
          if ( $status > 0 ) {
            $self->log("Created home parent directory ".$user->{"homedir"}." for user $username");            
          }
        }
    }

    my @opts=generate_opts($user);

    if (!$createHome) {
      push(@opts,"-M");
    }else{
      if($useLdap != 1){
        push(@opts,"-m");
      }
    }
    if($useLdap == 1){
      for (my $i =0; $i < @opts; $i++){
        #Because we will call with luseradd anf it doesn't know -G 
        if($opts[$i] eq '-G'){
          $opts[$i] ='';
          $opts[$i+1] ='';
        }
        #put password in quotes
        if($opts[$i] eq '-p'){
          $opts[$i+1] = '"'. $opts[$i+1]. '"';
        }
      }

    }

    $self->log($USERADD.' '.join(' ', @opts).' '.$user->{"name"});
    $self->verbose($USERADD.' '.join(' ', @opts).' '.$user->{"name"});
    # call useradd with generated options
    unless (execute ([($USERADD.' '.join(' ', @opts).' '.$user->{"name"})])){
      $self->warn("Failed to run " . $USERADD);
      return;
    }
    if ($?) {
      $self->warn("Failed to add user " . $user->{"name"});
    } else {
      if($useLdap == 1){
        # This is a horrible hack because luseradd doesn't work properly.
        # It doesn't set the password correctly. What is a discrace
        # FIXME: This really needs fixing
        modify_user ($self, $user, 0);
      }
    }
}



# Deletes a user using userdel.
# IN:  username
# OUT:
##########################################################################
sub delete_user {
##########################################################################
    my ($self, $username) = @_;
    my $firstchar=substr($username, 0, 1);


    if ($firstchar ne '+' && $firstchar ne '-' && $username ne 'root') {
      $self->log($USERDEL." ".$username);
      $self->verbose($USERDEL." ".$username);

      unless (execute ([$USERDEL, $username])) {
        $self->warn("Failed to call ". $USERDEL);
        return;
      }
      if ($?) {
        $self->warn("Failed to delete user ".$username)
      }

    }

}

# Configures login defaults based on profile.
# IN:  self (for logging), config tree, string indicating base
# point in config tree.
# OUT:
##########################################################################
sub configure_login_defs($$@) {
##########################################################################

    my ($self,$config,$base) = @_;

    if ($config->elementExists("$base/login_defs")) {   
        ## create backup
        copy("/etc/login.defs","/etc/login.defs.old")|| $self->error("Can't write to /etc/login.defs.old");
        
        my ($defs,$def,$val);
        $defs = $config->getElement("$base/login_defs");
        while ($defs->hasNextElement()) {
            my $element = $defs->getNextElement();
            
            $def=$element->getName();
            $def=~ tr/a-z/A-Z/;
            $val=$element->getValue();
            
            ## use NCM::Check::lines to replace values
            NCM::Check::lines("/etc/login.defs",
                              linere => $def.".*",
                              goodre => "$def $val",
                              good   => "$def $val");
            
        }
    }
}

# Sets fields in our internal user hash format based on fields
# set in the user hash retrieved directly from the profile.
# IN: ref to user hash to fill, ref to user hash from profile,
# name of user, uid of user
# OUT:
##########################################################################
sub fill_user_hash {
##########################################################################

    my ($user_hash, $prof_hash, $name, $uid)=@_;

    $user_hash->{"name"}=$name;

    if (exists $prof_hash->{"password"}) {
        $user_hash->{"password"}=$prof_hash->{"password"};
    }
    $user_hash->{"uid"}=$uid;

    
    if (exists $prof_hash->{"groups"}){
        my $grouplist=$prof_hash->{"groups"};

        $user_hash->{"pgroup"}=($prof_hash->{"groups"}->[0]);   
        $user_hash->{"groups"}=join(',',sort @$grouplist);
        
    }

    # N.B. the comment field in the profiles appears to 
    # be used for users' real names
    if (exists $prof_hash->{"comment"}) {
        $user_hash->{"gcos"}=$prof_hash->{"comment"};
    }
    
    if (exists $prof_hash->{"shell"}) {
        $user_hash->{"shell"}=$prof_hash->{"shell"};
    }
    if (exists $prof_hash->{"createHome"}) {
        $user_hash->{"createHome"}=$prof_hash->{"createHome"};
    }
    if (exists $prof_hash->{"homeDir"}) {
        $user_hash->{"homedir"}=$prof_hash->{"homeDir"};
        if ( $user_hash->{"createHome"} ) {
          my $status = $self->prepare_home($user_hash->{"homeDir"});
          unless ( $status ) {
            $self->error("can't create home parent directory ".$user_hash->{"homeDir"}."; skipping user $name");
            return 1;            
          }
          if ( $status > 0 ) {
            $self->log("Created home parent directory ".$user_hash->{"homeDir"}." for user $name");            
          }
        }
    }
    if (exists $prof_hash->{"createKeys"}) {
        $user_hash->{"createKeys"}=$prof_hash->{"createKeys"};
    }
}

# Retrieves existing groups from system and fills a hash.
# IN: self (for logging) 
# OUT: hash of lists containing groups (by name) for each user (by name)
##########################################################################
sub get_existing_user_groups_hash {
##########################################################################
    my ($self) = @_;

    my %user_groups;

    # get groups entries 
    while (my ($group, $passwd, $gid, $members) = getgrent) {
        next if $members =~ /^$/;
        my @members = split ' ', $members;
        $self->debug(5, "$group has '@members'\n");
        foreach my $user (@members) {
            $self->debug(5, "adding $user to $group\n");
            push @{ $user_groups{$user} }, $group;
        }
    }
    endgrent();

    # sort list for each user
    foreach my $user (keys %user_groups) {
        @{ $user_groups{$user} } = sort @{ $user_groups{$user} };
    }

    return %user_groups;
}

# Retrieves existing users from system and fills a set of user hashes.
# If this is done on a system that gets it's users over ldap it will deadlock
# IN: self (for logging) 
# OUT: hash of hashes containing existing users (keyed by name)
##########################################################################
sub get_existing_users {
##########################################################################

    my ($self,$username) = @_;
    
    my $getUserFunction;

    if ($username){
      $getUserFunction = \&getpwnam;
    }else{
      $getUserFunction = \&getpwent;
    }

    my %user_groups = $self->get_existing_user_groups_hash();

    my %existing_users;

    while(my $pw  = &$getUserFunction($username)){
        my %user_hash;
        $user_hash{'name'}=$pw->name;
        $user_hash{'password'}=$pw->passwd;
        $user_hash{'uid'}=$pw->uid;
        $user_hash{'gid'}=$pw->gid;
        $user_hash{'pgroup'}=getgrgid($pw->gid);
        if ($pw->comment) {
            $user_hash{'comment'}=$pw->comment;
        }
        $user_hash{'gcos'}=$pw->gecos;
        $user_hash{'homedir'}=$pw->dir;
        $user_hash{'shell'}=$pw->shell;
        
        # get full list of groups
        my $groups = "";
        if (exists $user_groups{$pw->name}) {
            $groups = join ',', @{ $user_groups{$pw->name} };
        }    
        $user_hash{'groups'}= $groups;
  
        $existing_users{$pw->name}=\%user_hash;
        last if($username);
    }
    endpwent(  );

    return %existing_users;
}

# Find out if a user is in /etc/passwd or from somewhere else (Ldap for example :)
# IN: self (for logging/warn), username to check against
# OUT: 1 if user is in /etc/passwd, 0 if not
##########################################################################
sub user_in_passwd {
##########################################################################
    my ($self, $user)= @_;
    my $returnVal = 0;

    # Only do it if we use ldap. Otherwise exit to save time
    if ($useLdap != 1){
      return 1;
    }

    unless (open PASSWD, "/etc/passwd"){
      $self->warn("Cannot open /etc/passwd for reading: $!");
      return;
    }

    while (my ($name) = split(/:/,<PASSWD>) ) {
      if ($user eq $name){
        $returnVal = 1;
        last;
      }
    }
    close PASSWD;
    return $returnVal;
}

# Compares hashes representing a configured user and an existing user.
# IN:  self (for logging), configured user hash, existing user hash
# OUT: string containing results of comparison

##########################################################################
sub compare_users {
##########################################################################
    my ($self, $cfguser,$existuser) = @_; 
    my $retcode = "unchanged";
    my @ACCOUNTFIELDS=(GCOS, HOMEDIR, NAME, UID, PASSWORD, SHELL, PGROUP,GROUPS);    

    foreach my $field (@ACCOUNTFIELDS) {

        # if profile has field but existing a/c does not,
        # then state is "mod". Should we remove fields
        # in existing accounts that aren't in the profile?
        if (defined $cfguser->{$field}) {
            if (not defined $existuser->{$field}) {
                $retcode="mod";
            }
            else {
                my $cfgfield=$cfguser->{$field};
                my $existfield;

                if (defined($existuser->{$field})) {
                    $existfield=$existuser->{$field};
                    $existfield =~ s/^"(.*)"$/$1/; # strip quotes

                    if ($cfgfield ne $existfield) {
                        $retcode="mod";
                        $self->log("$field not consistent with profile: (\"$cfgfield\",\"$existfield\")");
                    }
                    
                }
            }
        }
    }
    return $retcode;
}

# Delete groups not configured in the profile (excepting root group,
# and groups marked to be kept.
# IN:   self (for logging), safemode flag, ref to kept groups, ref to 
# hash of groups
# OUT:  
##########################################################################
sub delete_groups {
##########################################################################
    my ($self, $safemode, $kgroupsref, $groupsref) = @_;
    my %kept_groups=%$kgroupsref;
    my %groups=%$groupsref;
    my ($groupname, $val);
    my $retval;

    # delete groups 
    # special case: ignore groups starting with '+' or '-' to allow use of NIS 
    # special case: do not allow root to be deleted
    while (($groupname, $val) = each(%groups)) {
      my $firstchar=substr($groupname, 0, 1);
      if ($val eq 'old' && $firstchar ne '+' && $firstchar ne '-' &&
        $groupname ne 'root' && not(defined($kept_groups{$groupname}))) {
      
        my $primary = 0;
      
        # opening /etc/passwd shouldn't strictly be necessary as
        # we have got a list of existing users already ...
        my $gid = getgrnam($groupname);
        if (defined($gid) && $gid ne '') {
          unless(open PASSWD,"/etc/passwd"){
            $self->warn("Cannot open /etc/passwd for reading: $!");
            return;
          }

          while (my ($name, $pwd, $uid, $testgid) = split(/:/,<PASSWD>) ) {
            $primary = 1 if ($gid == $testgid);
          }
          close PASSWD;
        }

        $self->verbose($GRPDEL . " " . $groupname) if (!$primary);

        if (!$safemode && !$primary) {
          $self->log($GRPDEL . " " . $groupname);
          unless (execute ([$GRPDEL, $groupname])) {
            $self->warn("Failed to run" . $GRPDEL);
            return;
          }
          if ($?) {
            $self->warn("Failed to delete group ".$groupname);
          }
        } else {
          $self->warn("group $groupname not deleted because it's a primary group for some user");
        }
      }
    }
}

# Convert password files to/from shadow format as configured in profile.
# IN:  self (for logging), flag indicating shadow or non-shadow mode
# OUT: 
##########################################################################
sub shadow_passwords {
##########################################################################
    my ($self, $shadow) = @_;
    my $retval;

    if ($shadow eq 'true') {
        $self->log("Shadow passwords enabled: running ".PWCONV.",".GRPCONV);
        $self->verbose("Shadow passwords enabled: running ".PWCONV.",".GRPCONV);
        execute([PWCONV]);
        $retval=$?;
        execute ([GRPCONV]);
        $retval+=$?;
        $self->Warn("Failed to set shadow passwords") if ($retval);
    } elsif ($shadow eq 'false') {
        $self->verbose("Shadow passwords disabled: running ".PWUNCONV.",".GRPUNCONV);
        $self->log("Shadow passwords disabled: running ".PWUNCONV.",".GRPUNCONV);
        execute ([PWUNCONV]);
        $retval=$?;
        execute ([GRPUNCONV]);
        $retval+=$?;
        $self->Warn("Failed to unset shadow passwords") if ($retval);
    }
}

# Generate a set of user hashes for pool accounts.
# IN:  ref to hash of configured users, ref to base user hash,
# user name (unnecessary as in hash?)
# OUT: 
##########################################################################
sub generate_pool_users {
##########################################################################
    
    my ($self,$configured_users,$thisuser,$username)=@_;
    my $uid=$thisuser->{'uid'};
    my $poolSize=$thisuser->{"poolSize"};
    my $poolStart=$thisuser->{"poolStart"};
    my $homedir="";

    # Define home directory prefix and ensure parent exists if createHome=true
    if (exists($thisuser->{"homeDir"})) {
        $homedir=$thisuser->{"homeDir"};
    } else {
        $homedir="/home/".$username;
        $self->info("No base dir set for $username pool accounts, defaulting to $homedir.");
    }
    if ( $thisuser->{"createHome"} ) {
      my $status = $self->prepare_home($homedir);
      unless ( $status ) {
        $self->error("can't create home parent directory $homedir; skipping pool account $username");
        return 1;            
      }
      if ( $status > 0 ) {
        $self->log("Created home parent directory $homedir for pool account $username");
      }
    }
    

    # Get the ending index for pool accounts.  Create the field
    # specifier for the pool account suffix.
    my $poolEnd = ($poolSize>0) ? $poolStart+$poolSize-1 : $poolStart;

    my $poolDigits=length("$poolEnd");

    if (exists $thisuser->{"poolDigits"}) {
        $poolDigits=$thisuser->{"poolDigits"};
    }

    
    my $field = "%0" . $poolDigits . "d";
    
    # Now add or modify the user. 
    for my $j ($poolStart .. $poolEnd) {
        my $suffix = ($poolSize>0) ? sprintf($field, $j) : '';
        my $uname = $username . $suffix;
        $configured_users->{$uname}={};
        my $myuid=$uid+$j;

        fill_user_hash($configured_users->{$uname}, 
                       $thisuser, $uname, $myuid);

        
        my $poolhomedir=$homedir.$suffix;
        $configured_users->{$uname}{"homedir"}=$poolhomedir;
        if (exists $thisuser->{"createHome"}) {
            $configured_users->{$uname}{"createHome"}=$thisuser->{"createHome"};
        }
        if (exists $thisuser->{"createKeys"}) {
            $configured_users->{$uname}{"createKeys"}=$thisuser->{"createKeys"} 
        }
    }
}

# Retrieve info about users from profile and use it to fill user hashes.
# IN:  config (to access profile), base (root point in profile tree)
# OUT:
##########################################################################
sub get_users_from_profile {
##########################################################################
    my ($self,$config, $base) = @_;
    my %configured_users;
    
    # get list of users from profile and use info to fill list of 
    # user hashes in our internal format
    # N.B. includes generation of pool accounts
    if ($config->elementExists("$base/users")) {
        my $users_resource = $config->getElement("$base/users");
        my $uhashref = $users_resource->getTree;
        my %uhash = %$uhashref;

        foreach my $user (keys %uhash) {
            my $thisuserref=$uhash{$user};
            my %thisuser=%$thisuserref;

            my $uid=$thisuser{'uid'};

            if (my $poolSize=$thisuser{"poolSize"}) {
                generate_pool_users($self,\%configured_users, \%thisuser, $user);
            } else { # non pool accounts
                $configured_users{$user}={};
                fill_user_hash($configured_users{$user}, \%thisuser, $user, $uid);
            }
        }
    }

    return %configured_users;
}

# Read list of users and groups to be kept from the profile.
# IN:  config, base (to access profile), refs to hashes of groups, users
# OUT:
##########################################################################
sub get_kept_groups_and_users {
##########################################################################

    my ($config, $base,$kept_groups,$kept_users)=@_;


    if ($config->elementExists("$base/kept_groups")) {
        my $resource = $config->getElement("$base/kept_groups");
        while ($resource->hasNextElement()) {
            my $element = $resource->getNextElement();
            my $grp = $element->getName();
            $kept_groups->{$grp} = 1
            }
        # add root group
        $kept_groups->{"root"} = 1;
    }
    if ($config->elementExists("$base/kept_users")) {
        my $resource = $config->getElement("$base/kept_users");
        while ($resource->hasNextElement()) {
            my $element = $resource->getNextElement();
            my $user = $element->getName();
            $kept_users->{$user} = 1
            }
        # add root user
        $kept_users->{"root"} = 1;
    }
}

# Process groups according to profile: add or modify. (Deleting is done
# separating after user config to avoid deleting groups that are primary
# groups for configured users.
# IN:  self (for logging), config,base (to access profile), 
# ref to groups hash, safemode flag
# OUT:
##########################################################################
sub process_groups {
##########################################################################

    my ($self, $config, $base, $groups, $safemode) = @_;

    unless (open GROUP,"/etc/group"){
      $self->warn("Cannot open /etc/group for reading: $!");
      return;
    }
    my @groupinfo;
    my %existinggroups;
    my $groupname;
    my $retval;

    while ((@groupinfo) = split(/:/,<GROUP>)) {
        $groupname=$groupinfo[0];
        my $gid= $groupinfo[2];
        $existinggroups{$groupname} = $gid;
        $groups->{$groupname} = 'old';
    }
    close GROUP;

   # create root group if it doesn't exist (can happen!)
    if ( !(exists($existinggroups{'root'})) ) {
        my @group_opt=();
        my $cmd=$GRPADD;
        my $groupname='root';
        push(@group_opt,'-g'.'0');
        $self->warn("No root group, trying to create one now.");
        $self->log(join(" ",$cmd,@group_opt)." ".$groupname);
        $self->verbose(join(" ",$cmd,@group_opt)." ".$groupname); 
        execute ([$GRPADD, @group_opt, 'root']);
    }

    # process groups listed in auth resource "groups"
    # if already existing call groupmod and change %groups value to "mod"
    # otherwise call groupadd and set %groups value to "new"
    if ($config->elementExists("$base/groups")) {
        my $groups_resource = $config->getElement("$base/groups");

  while ($groups_resource->hasNextElement()) {
      my $element = $groups_resource->getNextElement();
      
      # Collect options for this group.
      my @group_opt=();
      
      # The key is the name of the group.
      $groupname=$element->getName();
      
      my $prefix = "$base/groups/$groupname";
      my $gid="none";
      # Add gid if specified.
      if ($config->elementExists("$prefix/gid")) {
        $gid = $config->getElement("$prefix/gid")->getValue();
        push(@group_opt,'-g'.$gid);
      }
      
      # Define value necessary.
      my $cmd = $GRPADD;

      my $state = 'new';
      if (defined($groups->{$groupname}) && $groups->{$groupname} ne "new") {
          $cmd = $GRPMOD;
          $state = 'mod';
      }
      
      # Run the command to modify or create a group.
      $groups->{$groupname} = $state;
      
      if ($safemode) {
          $self->log("noaction mode: not modifying group $groupname");
      } else {
          my $oldgid = $existinggroups{$groupname}|| "NEW";
          if ($gid ne "none" || ($oldgid && ($gid ne $oldgid))) {        
            $self->log(join(" ",$cmd,@group_opt)." ".$groupname);
            $self->verbose(join(" ",$cmd,@group_opt)." ".$groupname);
        
            unless (execute ([$cmd, @group_opt, $groupname])) {
              $self->warn("Failed to call ". $cmd);
              return;
            }
            if ($?) {
              $self->warn("Failed to ". $cmd ." group ". $groupname)
            }
          }
        }
      }
    }
}


##########################################################################
sub Configure($$@) {
##########################################################################
    
    my ($self, $config) = @_;

    # Define paths for convenience. 
    my $base = "/software/components/accounts";

    # Number of accounts added
    my $no_users_added=0;

    # Set this to 1 for debugging.  Normally we want to actually 
    # make the changes. (Also could be used to implement noaction!)
    my $safemode = 0;
    if ($NoAction) {
        $self->verbose("Running in noaction mode, no changes will be made.\n");
        $safemode=1;
    }

    my $removeAccounts=0;
    # check whether unconfigured accounts should be removed
    if ($config->elementExists("$base/remove_unknown")) {
        $removeAccounts=($config->getValue("$base/remove_unknown") eq 'true');
    }
    
    # check if the system is configured to use ldap 
    if ($config->elementExists("$base/ldap") && ($config->getValue("$base/ldap") eq "true")) {
      $self->verbose("Running in Ldap mode");
      $useLdap = 1;
      # Use the libuser programs
      $USERADD = "/usr/sbin/luseradd";
      #$USERMOD = "/usr/sbin/usermod";
      $USERDEL = "/usr/sbin/luserdel";
      $GRPDEL = "/usr/sbin/lgroupdel";
      $GRPADD = "/usr/sbin/lgroupadd";
      #$GRPMOD = "/usr/sbin/groupmod";
      #$SYSID = "/usr/sbin/id";
    }
    
    ## Ensure that passwd and group are ok
    my $shadowOk = 0;
    if ($config->elementExists("$base/shadowpwd")) {
        $shadowOk = $config->getValue("$base/shadowpwd");
        if($shadowOk eq 'true'){
          shadow_passwords($self, $shadowOk);
          $self->debug(5, "Shadow is true so running pwconv and grpconv");
        }
    }
    
    ## configure /etc/login.defs
    configure_login_defs($self, $config, $base);

    # This component's code was originally taken from the edg-lcfg-auth 
    # component, but has now been refactored.
    
    my %groups;  # old groups to delete, new groups to add and groups to modify

    my $retval; # temp variables

    # Collect the groups and users which must be kept if they exist.
    my (%kept_groups, %kept_users);
    get_kept_groups_and_users($config,$base,\%kept_groups,\%kept_users);

    #########################
    # Start processing groups
    #########################
    process_groups($self, $config, $base, \%groups, $safemode);

    # removal of old groups is done after processing users because we don't
    # remove groups that are still primary group for a user
    
    
    #########################
    # Start processing users
    #########################

  
    # read list of existing users and options from passwd file
    my %existing_users ;
    if ($useLdap != 1){
        %existing_users=get_existing_users($self);
    }
    if ( ! (exists($existing_users{'root'}) ) ) {
        $self->warn("No root user, creating one now.");
        my %root_user;
        $root_user{'name'}='root';
        $root_user{'gid'}=0;
        $root_user{'homedir'}='/root';
        $root_user{'pgroup'}='root';
        $root_user{'uid'}=0;
        $self->add_user(\%root_user,0);    
    }

    # set root password
    if ($config->elementExists("$base/rootpwd")) {
        my $rootpwd=$config->getValue("$base/rootpwd");
        if (defined $rootpwd && $rootpwd ne '') {
            if ($safemode) {
                $self->log("Not changing root password while in safe mode");
            } else {
                unless (execute ([$USERMOD . " -p ". "'" . $rootpwd. "'" .  " root"])){
                  $self->warn("Failed to run" . $USERMOD);
                  return;
                }
                if ($?) {
                  $self->warn("Failed to set root password")
                }
            }
        }
    }

    # read list of users configured in the profile
    my %configured_users=get_users_from_profile($self,$config, $base);


    # hash to record action to be taken for each account
    my %processed_users;
    
    
    # compare each user in the profile to existing account
    foreach my $cfguser (sort keys %configured_users) {
        my $cfguserhash=$configured_users{$cfguser};

        $self->debug(5,"\$profile : ". Dumper(\$cfguserhash));
        $processed_users{$cfguser}='unchanged';

        my $pw = getpwnam($cfguser);

        #The get user_in_passwd will always be true if not using ldap
        if ($pw && user_in_passwd($self,$cfguser)) {
            #If in ldap mode and user is in /etc/passwd get data for him
            if ($useLdap == 1){
              %existing_users=get_existing_users($self,$cfguser);
            }
            my $exuserhash=$existing_users{$cfguser};
            $self->debug(5,"\$onsys : ". Dumper(\$exuserhash));
            $processed_users{$cfguser}=compare_users($self, $cfguserhash, $exuserhash);
        } else {
            $processed_users{$cfguser}='add';
        }

    }
    $self->debug(5,Dumper(\%processed_users));
    
    $self->info("Finished scanning existing users on system.");
   


    # for existing users not in profile set state to 'del'
    if ($removeAccounts){
        # read list of existing users and options from passwd file
        my %existing_users=get_existing_users($self);
        foreach my $existuser (sort keys %existing_users) {
            if (not exists $processed_users{$existuser}) {
                $processed_users{$existuser}='del';
            }
        }
    }


    open(NEWUSERSF,">".NEWUSERLIST);
    open(NEWPASSF,">".NEWPASSLIST);
    # Process list of users
    foreach my $usertoproc (sort keys %processed_users) {
        my $prefix = "$base/users/$usertoproc";         
        my $state=$processed_users{$usertoproc};
        my $createHome = 1;
        if (exists $configured_users{$usertoproc}{"createHome"}) {
            $createHome = $configured_users{$usertoproc}{"createHome"};
        }
        my $createKeys = 0;
        if (exists $configured_users{$usertoproc}{"createKeys"}) {
            $createKeys = $configured_users{$usertoproc}{"createKeys"};
        }           

        if ($state eq "del") {
            # check safe mode, removeAccounts, kept accounts
            my $kept=defined($kept_users{$usertoproc});
            
            if ($removeAccounts && !($safemode) && !$kept) {
                delete_user($self, $usertoproc);
            }

        } elsif ($state eq "add") {
            if (!$safemode) {   
#               add_user($self, $configured_users{$usertoproc},$createHome);
                # Output to file for newusers.
                # Do not check home directory parents here, this has already been done
                # with some optimization for pool accounts.
                $no_users_added++;
                my $userclass=$configured_users{$usertoproc};
                my $ushell="";
                if (exists $userclass->{"shell"}) {
                    $ushell=$userclass->{"shell"};
                }
                else {
                    $ushell="/bin/bash";
                }
                print(NEWUSERSF $userclass->{"name"}.":x:".$userclass->{"uid"}.":".getgrnam($userclass->{"pgroup"}).":\"".$userclass->{"gcos"}."\":".$userclass->{"homedir"}.":".$ushell."\n");
                my $upass="";
                if (exists $userclass->{"password"}) {
                    $upass=$userclass->{"password"};
                }
                else {
                    $upass="!NP*";
                }
                  
                print(NEWPASSF $userclass->{"name"}.":".$upass."\n");
            }
            else {
                $self->log("noaction mode: not adding user $usertoproc");
            }
            
            # Determine if ssh keys should be generated for this user.
            if ($createKeys && $createHome && !$safemode) {
                $self->keygen($usertoproc);
            }

        } elsif ($state eq "mod" ) {
            $self->info("User $usertoproc needs to be modified");
            if (!$safemode) {        
                modify_user($self, $configured_users{$usertoproc}, $createHome);
            } else {
                $self->log("noaction mode: not modifying user $usertoproc");
            }
        }

        elsif ($state eq "unchanged" ) {

        }

        else {
            $self->error("User $usertoproc in unknown state");
        }

    }

    close NEWUSERSF;
    
    # bulk add new users
    execute([NEWUSERS,NEWUSERLIST]);
    if ($no_users_added > 0 ) {
        $self->info("Added ".$no_users_added." users.");
    }
 
    my $pipestring="|".CHPASSWD." -e";
    my $pipe;
    open $pipe, $pipestring;

    close NEWPASSF;
    # reopen for reading
    open NEWPASSF,NEWPASSLIST;

    while (<NEWPASSF>) {
        my $line = $_;
        chomp ($line);
        print $pipe $line, "\n";
    }
    close NEWPASSF;
    close $pipe;

    # delete the temp files we used as input
    unlink NEWPASSLIST;
    unlink NEWUSERLIST;

    # delete groups not in the profile
    if ($removeAccounts){
        delete_groups($self, $safemode, \%kept_groups, \%groups);
    }

    # shadow passwords
    my $shadow = 0;
    if ($config->elementExists("$base/shadowpwd")) {
        $shadow = $config->getValue("$base/shadowpwd");
    }

    if ($safemode) {
        $self->log("Not activating shadow passwords while in safe mode");
    } else {
        shadow_passwords($self, $shadow);
    }

    # set file permissions
    chmod(0644, "/etc/passwd");
    chmod(0644, "/etc/group");
    
    return 1;
}

# Generate ssh keys for a user.  This was lifted from the poolaccounts
# LCFG object written by Steve Traylen.  
sub keygen {

    my ($self,$user) = @_;

    # Get the UID, GID, and home directory of user.  There seems to be
    # a race condition when getpwnam is called the first time causes
    # the information not to be returned.  So it is called twice below
    # to avoid this. 
    my @dummy = getpwnam($user);
    my ($uid, $gid, $home) = (getpwnam($user))[2,3,7];

    unless (defined($uid) && defined($gid) && defined($home)) {
        $self->warn("User doesn't exist: $user");
        return;
    }

    ####################################################
    # Set the EUID, and EGID to cope with root_squashes.
    $) = $gid;
    $> = $uid;

    ###################################################
    # Create the .ssh directory.
    mkdir("$home/.ssh") unless (-d "$home/.ssh") ;

    ###################################################
    # Create the ssh 2 keypair.
    if (! -f "$home/.ssh/id_rsa") {
        $> = 0 ; $) = 0 ;
        $self->Info("Generating RSA2 key for $user") ;
        $) = $gid; $> = $uid;
        my @cmd = ('/usr/bin/ssh-keygen','-t','rsa','-q','-N','',
                   '-C',$user,'-f',"$home/.ssh/id_rsa") ;
        execute (\@cmd);
        my $retval = $?;
        if ( $retval != 0 ) {
            $> = 0 ; $) = 0 ;
            $self->Fail("Failed to generate key for $user.") ;
        }
    }

    ###################################################
    # Create the ssh 1 keypair.
    if (! -f "$home/.ssh/identity") {
        $> = 0 ; $) = 0 ;
        $self->Info("Generating RSA1 key for $user") ;
        $) = $gid ; $> = $uid ;
        my @cmd = ('/usr/bin/ssh-keygen','-t','rsa1','-q','-N','',
                   '-C',$user,'-f',"$home/.ssh/identity") ;
        execute (\@cmd);
        my $retval = $?;
        if ( $retval != 0 ) {
            $> = 0 ; $) = 0 ;
            $self->Fail("Failed to generate key for $user.") ;
        }
    }

    ##################################################
    # Create the authorised keys file.
    unless(open(AUTH,">$home/.ssh/authorized_keys")){
      $self->warn("Cannot open $home/.ssh/authorized_keys: $!");
      return;
    }
    unless(open(PUB,"<$home/.ssh/identity.pub")){
      $self->warn("Cannot open $home/.ssh/identity.pub:  $!");
      return;
    }
    while (<PUB>) {
        print AUTH $_ ;
    }
    close(PUB);
    unless(open(PUB,"<$home/.ssh/id_rsa.pub")){
      $self->warn("Cannot open $home/.ssh/id_rsa.pub:  $!");
      return;
    }

    while (<PUB>) {
        print AUTH $_ ;
    }
    close(PUB);
    close(AUTH) ;
    ##################################################
    # Set the EUID and EGID back to what they should be.
    $> = 0 ;
    $) = 0 ;
}

# escape the string so it is OK for a command line
sub quote_string($) {
    my $s = shift;
    $s =~ s%\\%\\\\%g;
    $s =~ s%\"%\\\"%g;
    return  '"' . $s . '"';
}

1;      # Required for PERL modules
