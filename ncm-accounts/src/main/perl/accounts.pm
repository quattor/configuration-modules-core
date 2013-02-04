# #
# Software subject to following license(s):
#   Apache 2 License (http://www.opensource.org/licenses/apache2.0)
#   Copyright (c) Responsible Organization
#

# #
# Current developer(s):
#   Luis Fernando Muñoz Mejías <Luis.Munoz@UGent.be>
#

# #
# Author(s): Jane SMITH, Joe DOE
#

# #
      # accounts, 12.12.1-SNAPSHOT, SNAPSHOT20121231164032, 20121231-1740
      #

package NCM::Component::accounts;

use strict;
use warnings;

use NCM::Component;

use LC::Exception;
use EDG::WP4::CCM::Element;
use CAF::FileWriter;
use CAF::FileEditor;
use CAF::Process;
use Fcntl qw(SEEK_SET);
use File::Basename;
use File::Path;
use LC::Find;
use LC::File qw(copy makedir);


our @ISA = qw(NCM::Component);
our $EC=LC::Exception::Context->new->will_store_all;

our $NoActionSupported = 1;

# UID for user structures, GID for group structures.
use constant ID => 2;
# List of groups for users, list of members for groups.
use constant IDLIST => 3;
# Name of the group or user
use constant NAME => 0;
# Home directory of the user
use constant HOME => 5;
# Shell
use constant SHELL => 6;
# GCOS
use constant GCOS => 4;
# Home directory, on getpw* output
use constant PWHOME => 7;

use constant EXTRA_FIELD => 9;

# Password field in /etc/shadow.
use constant PASSWORD_FIELD => 1;

# Pan path for the component configuration.
use constant PATH => "/software/components/accounts";

use constant PASSWD_FILE => "/etc/passwd";
use constant GROUP_FILE => "/etc/group";
use constant SHADOW_FILE => "/etc/shadow";
use constant LOGINDEFS_FILE => "/etc/login.defs";

use constant UID_MIN_KEY => "UID_MIN";
use constant GID_MIN_KEY => "GID_MIN";
use constant UID_MIN_DEF => 100;
use constant GID_MIN_DEF => 100;

# Mapping between configuration schema and /etc/login.defs keywords.
# One entry must exist for each login.defs keyword that is manageable through this component.
# Key is a configuration property, value is the matching login.defs keyword.
my %logindefs_mapping = ('create_home', 'CREATE_HOME', 
                         'gid_max', 'GID_MAX',
                         'gid_min', 'GID_MIN',
                         'pass_max_days', 'PASS_MAX_DAYS',
                         'pass_min_days', 'PASS_MIN_DAYS',
                         'pass_min_len', 'PASS_MIN_LEN',
                         'pass_warn_age', 'PASS_WARN_AGE',
                         'uid_max', 'UID_MAX',
                         'uid_min', 'UID_MIN',
                         );

# Default groups for the root account.
use constant ROOT_DEFAULT_GROUPS => qw(root adm bin daemon sys disk);

use constant SKELDIR => "/etc/skel";

# Expands the profile to the list of desired accounts, including
# pools.
sub compute_desired_accounts
{
    my ($self, $profile) = @_;

    my $ds = {};

    $self->verbose("Preparing map of desired accounts in the system");
    while (my ($k, $v) = each(%$profile)) {
	if (exists($v->{poolSize})) {
	    foreach my $i (0..$v->{poolSize}-1) {
		my $account = sprintf("%s%0$v->{poolDigits}d", $k,
				      $v->{poolStart}+$i);
		while (my ($l, $m) = each(%$v)) {
		    $ds->{$account}->{$l} = $m;
		}
		$ds->{$account}->{uid} = $v->{uid}+$i;
		$ds->{$account}->{name} = $account;
		if ($v->{homeDir}) {
		    my $home =  sprintf("%s%0$v->{poolDigits}d", $v->{homeDir},
					$v->{poolStart}+$i);
		    $ds->{$account}->{homeDir} = $home;
		}
	    }
	}
	else {
	    $ds->{$k} = $v;
	    $ds->{$k}->{name} = $k;
	}
    }

    return $ds;
}

# Returns a map for /etc/groups.
sub build_group_map
{
    my $self = shift;

    my %rt;

    my $fh = CAF::FileEditor->new(GROUP_FILE, log => $self);
    $fh->cancel();
    seek($fh, 0, SEEK_SET);

    $self->verbose("Building group map");

    while (my $l = <$fh>) {
      chomp($l);
      next unless $l;
      $self->debug(2, "Read group line $l");
      my @flds = split(":", $l);
      my $h = { name => $flds[NAME] };
      next unless $h->{name};
      $h->{gid} = $flds[ID];
      my %mb;
      if ($flds[IDLIST]) {
          %mb = map(($_ => 1), split(",", $flds[IDLIST]));
      }
      $h->{members} = \%mb;
      $rt{$h->{name}} = $h;
    }

    return \%rt;
}

# Returns a map for /etc/passwd
sub build_passwd_map
{
    my ($self, $groups) = @_;

    my $fh = CAF::FileEditor->new(PASSWD_FILE, log => $self);
    $fh->cancel();
    seek($fh, 0, SEEK_SET);

    my (%rt, $ln);

    $self->verbose("Building an account map");

    $ln = 0;
    while (my $l = <$fh>) {
     chomp($l);
     next unless $l;
     $self->debug(2, "Read line $l");
     my @flds = split(":", $l);
     my $h = { name => $flds[NAME] };
     next unless $h->{name};
     $h->{uid} = $flds[ID];
     $h->{main_group} = $flds[IDLIST];
     $h->{homeDir} = $flds[HOME] || "";
     $h->{shell} = $flds[SHELL] || "";
     $h->{comment} = $flds[GCOS] || "";
     $h->{ln} = ++$ln;
     $rt{$h->{name}} = $h;
    }

    while (my ($group, $st) = each(%$groups)) {
      foreach my $acc (keys(%{$st->{members}})) {
          push(@{$rt{$acc}->{groups}}, $group) if exists($rt{$acc});
      }
    }

    return \%rt;
}

# Returns a map for /etc/login.defs
sub build_login_defs_map
{
    my ($self,$login_defs) = @_;

    my $fh = CAF::FileEditor->new(LOGINDEFS_FILE, log => $self);
    seek($fh, 0, SEEK_SET);

    my (%rt, $ln);

    $self->verbose("Retrieving ".LOGINDEFS_FILE." parameters");

    $ln = 0;
    while (my $l = <$fh>) {
      chomp($l);
      next unless $l;
      $l =~ s/^\s+//;
      next if ( $l =~ /^#/);
      $self->debug(2, "Read line $l");
      my @flds = split(/\s+/, $l);
      $rt{$flds[0]} = $flds[1];
    }

    while (my ($p,$v) = each(%{$login_defs}) ) {
      if ( exists($logindefs_mapping{$p}) ) {
        $rt{$logindefs_mapping{$p}} = $v;
        $fh->add_or_replace_lines(qr/^\s*$logindefs_mapping{$p}\s+/,
                                  qr/^\s*$logindefs_mapping{$p}\s+$v\s*$/,
                                  $logindefs_mapping{$p}."\t".$v,
                                  ENDING_OF_FILE,
                                 );
        $self->debug(1, LOGINDEFS_FILE.": ".$logindefs_mapping{$p}." set to ".$v);
      } else {
        $self->warn("No ".LOGINDEFS_FILE." matching keyword defined for login_defs/$p property (internal inconsistency)")
      }
    }

    if ( !exists($rt{&UID_MIN_KEY}) ) {
      $self->warn(UID_MIN_KEY." not defined. Using default value (".UID_MIN_DEF.")");
      $rt{&UID_MIN_KEY} = UID_MIN_DEF;
    }
    if ( !exists($rt{&GID_MIN_KEY}) ) {
      $self->warn(GID_MIN_KEY." not defined. Using default value (".GID_MIN_DEF.")");
      $rt{&GID_MIN_KEY} = GID_MIN_DEF;
    }

    $fh->close();
    
    return \%rt;
}

# Add /etc/shadow information to the map build from /etc/passwd
sub add_shadow_info
{
    my ($self, $passwd) = @_;

    my $fh = CAF::FileEditor->new(SHADOW_FILE, log => $self);
    $fh->cancel();
    seek($fh, 0, SEEK_SET);

    $self->verbose("Adding passwords to the accounts map");

    while (my $l = <$fh>) {
      next unless $l;
      my @flds = split(":", $l);
      if ( exists($passwd->{$flds[NAME]}) ) {
        $passwd->{$flds[NAME]}->{password} = $flds[PASSWORD_FIELD];
      } else {
        $self->debug(2,"Shadow entry ' ".$flds[NAME]."' ignored: no matching entry in password file");
      }
    }
}


# Returns three hash references: one for accounts, another one for
# groups, and the last one for shadow.
#
# Each member of each hash is a hash reference with a meaningful name
# for each field. If a field is a complex one (say, the list of
# members of a group, it will be a hash as well).
sub build_system_map
{
    my ($self,$login_defs) = @_;

    my $groups = $self->build_group_map();
    my $passwd = $self->build_passwd_map($groups);
    $self->add_shadow_info($passwd);
    my $logindefs = $self->build_login_defs_map($login_defs);

    $self->info(sprintf("System has %d accounts in %d groups",
			scalar(keys(%$passwd)), scalar(keys(%$groups))));

    return { groups => $groups, passwd => $passwd, logindefs => $logindefs};
}

# Deletes any groups in the $system not in the $profile, excepting
# those in the $kept list.
# Adjuss
sub delete_groups
{
    my ($self, $system, $profile, $kept, $preserve_system_groups) = @_;

    while (my ($group, $cfg) = each(%{$system->{groups}})) {
      if (!(exists($profile->{$group}) ||
            exists($kept->{$group}) || 
            ($preserve_system_groups) && ($cfg->{gid} < $system->{logindefs}->{&GID_MIN_KEY})
           )) {
	      $self->debug(2, "Marking group $group for removal");
	      delete($system->{groups}->{$group});
      }
    }
}

# Applies to $system the groups in $profile, by adding or modifying as
# needed.
sub apply_profile_groups
{
    my ($self, $system, $profile) = @_;

    while (my ($group, $cfg) = each(%$profile)) {
      if (!exists($system->{groups}->{$group})) {
        $self->debug(2, "Scheduling addition of group $group");
        $system->{groups}->{$group} = { name => $group,
                                        members => {},
                                        gid => $cfg->{gid}};
      } elsif ($system->{groups}->{$group}->{gid} != $cfg->{gid}) {
        $self->debug(2, "Changing gid of group $group to $cfg->{gid}");
        $system->{groups}->{$group}->{gid} = $cfg->{gid};
      }
    }
}

# Aligns groups in the $system to the description in the $profile,
# knowing that $kept groups shouldn't be removed ever (but they can be
# modified), and other groups in the system but not in the profile can
# be removed only if $remove_unknown allows for it.
sub adjust_groups
{
    my ($self, $system, $profile, $kept, $remove_unknown, $preserve_system_accounts) = @_;

    $self->verbose("Adjusting groups");

    $self->delete_groups($system, $profile, $kept, $preserve_system_accounts) if $remove_unknown;
    $self->apply_profile_groups($system, $profile);
}

# Deletes from the $system an $account.
sub delete_account
{
    my ($self, $system, $account) = @_;

    foreach my $i (@{$system->{passwd}->{$account}->{groups}}) {
	$self->debug(2, "Deleting account $account from group $i");

	if (exists($system->{groups}->{$i})) {
	    delete($system->{groups}->{$i}->{members}->{$account});
	}
    }

    delete($system->{passwd}->{$account});
}

# Adds to $system the account named $name, with the properties
# described in $cfg.
sub add_account
{
    my ($self, $system, $name, $cfg) = @_;

    foreach my $i (@{$cfg->{groups}}) {
	$self->debug(3, "Reviewing group $i for account $name");
	if (exists($system->{groups}->{$i})) {
	    $system->{groups}->{$i}->{members}->{$name} = 1;
	    # Pool accounts share their group structure. If it has
	    # already been changed, we need to do no more.
	} elsif ($i !~ m{^\d+$}) {
	    $self->debug(2, "Account $name assigned to non-local group $i");
	    my @g = getgrnam($i);
	    if (@g) {
		$i = $g[ID];
		$self->debug(2, "Account $name resolved in group $i")
	    } else {
		$self->error("Not found group $i for account $name. Skiping");
		return;
	    }
	}
    }

    if ($cfg->{groups}->[0] =~ m{^\d+$}) {
      $cfg->{main_group} = $cfg->{groups}->[0];
    } else {
      $cfg->{main_group} = $system->{groups}->{$cfg->{groups}->[0]}->{gid};
    }
    $cfg->{password} ||= "!";
    $system->{passwd}->{$name} = $cfg;
}

sub delete_unneeded_accounts
{
    my ($self, $system, $profile, $kept, $preserve_system_accounts) = @_;

    while (my ($account, $cfg) = each(%{$system->{passwd}})) {
      if (!(exists($profile->{$account}) ||
            exists($kept->{$account}) ||
            ($preserve_system_accounts) && ($cfg->{uid} < $system->{logindefs}->{&UID_MIN_KEY}) ||
            ($account eq 'root')
           )) {
        $self->debug(2, "Marking account $account for deletion");
        $self->delete_account($system, $account);
      }
    }
    # Remove unneeded group members that may come from LDAP/NIS/other
    # sources.
    while (my ($group, $cfg) = each(%{$system->{groups}})) {
      foreach my $m (keys(%{$cfg->{members}})) {
        if (!exists($system->{passwd}->{$m})) {
          delete($cfg->{members}->{$m});
        }
      }
    }
}

# Adds or modifies to $system the needed accounts in $profile
sub add_profile_accounts
{
    my ($self, $system, $profile) = @_;

    while (my ($account, $cfg) = each(%{$profile})) {
	if (exists($system->{passwd}->{$account})) {
	    $self->debug(2, "Account $account exists in the system. ",
			 "Regenerating from scratch");
	    # Inherit the existing password if not specified in the profile.
	    if (!exists($cfg->{password})) {
		$self->debug(1, "Account $account inherits ",
			     "password from the system");
		$cfg->{password} = $system->{passwd}->{$account}->{password};
	    }
	    # Inherit the existing shell if it absent or an empty string in the profile.
	    if (!exists($cfg->{shell}) || (length($cfg->{shell}) == 0)) {
		$self->debug(1, "Account $account: current ",
			     "shell preserved");
		$cfg->{shell} = $system->{passwd}->{$account}->{shell};
	    }
	    $self->delete_account($system, $account);
	}
	$self->debug(2, "Adding account $account to the system");
	$self->add_account($system, $account, $cfg);
    }
}

# Aligns the accounts in the $system to those in the
# $profile. Accounts in $kept are not removed even if they don't
# belong to the $profile.
sub adjust_accounts
{
    my ($self, $system, $profile, $kept, $remove_unknown, $preserve_system_accounts) = @_;

    $self->verbose("Adjusting accounts");

    $self->delete_unneeded_accounts($system, $profile, $kept, $preserve_system_accounts)
	if $remove_unknown;

    $self->add_profile_accounts($system, $profile);

}

# Returns a normal user structure from the fields related to root in
# the profile.
sub compute_root_user
{
    my ($self, $system, $tree) = @_;

    my $g = $system->{passwd}->{root}->{groups};

    if (!$g || !@$g) {
	$self->warn ("No groups found for root in the system. ",
		     "Assigning default ones: ",
		     join(", ", ROOT_DEFAULT_GROUPS));
	$g = [ROOT_DEFAULT_GROUPS];
    } else {
	my @f = grep($_ ne "root", @$g);
	$g = [ "root", @f];
    }

    my $u = { uid => 0,
	      groups => $g,
	      password => ($tree->{rootpwd}
			  || $system->{passwd}->{root}->{password}
			  || '!'),
	      shell => $tree->{rootshell} ||
		  $system->{passwd}->{root}->{shell} || "/bin/bash",
	      homeDir => "/root",
	      main_group => 0,
	      comment => "root",
	      name => 'root',
	      ln => $system->{passwd}->{root}->{ln}
	    };
    return $u;
}

# Returns whether the groups in the system are consistent.
sub groups_are_consistent
{
    my ($self, $groups) = @_;

    my $ok = 1;
    my %ids;

    $self->verbose("Checking for groups consistency");
    while (my ($group, $st) = each(%$groups)) {
	$self->debug(2, "Checking for consistency of group $group");
	if (exists($ids{$st->{gid}})) {
	    $self->error("Collision found between groups $group and ",
			 $ids{$st->{gid}}, " for id $st->{gid}");
	    $ok = 0;
	} else {
	    $ids{$st->{gid}} = $group;
	}
    }
    return $ok;
}

# Returns whether the accounts in the system are consistent (have
# unique IDs and all the groups they belong to actually exist).
sub accounts_are_consistent
{
    my ($self, $accounts, $groups) = @_;

    $self->verbose("Checking for account consistency");

    my $ok = 1;
    my %ids;



    while (my ($account, $st) = each(%$accounts)) {
	$self->debug(2, "Checking for consistency of account $account");
	if (exists($ids{$st->{uid}})) {
	    $self->error("Collision found between accounts $account and ",
			 "$ids{$st->{uid}} for id $st->{uid}");
	    $ok = 0;
	} else {
	    $ids{$st->{uid}} = $account;
	}
    }
    return $ok;
}

# Returns whether the $system is consistent. That is: that group IDs
# are unique, that all account IDs are unique, and that all the groups
# accounts belong to actually exist.
sub is_consistent
{
    my ($self, $system) = @_;

    $self->verbose("Checking for system consistency");
    return  $self->groups_are_consistent($system->{groups}) &&
      $self->accounts_are_consistent($system->{passwd});
}

# Commits the group configuration.
sub commit_groups
{
    my ($self, $groups) = @_;

    my (@group, @ln, $fh);

    $self->verbose("Preparing group file");

    while (my ($g, $cfg) = each(%$groups)) {
      @ln =  ($g,
              "x",
              $cfg->{gid},
              join(",", keys(%{$cfg->{members}}))
             );
      push(@group, join(":", @ln));
    }

    $self->info("Committing ", scalar(@group), " groups");

    $fh = CAF::FileWriter->new(GROUP_FILE, log => $self,
                               backup => ".old");
    print $fh join("\n", @group, "");
    $fh->close();
}

# Compares two account structures, as they're going to be sorted.
sub accounts_sort($$)
{
    my ($a, $b) = @_;

    my $cmp;

    if (exists($a->{ln}) && exists($b->{ln})) {
	$cmp = $a->{ln} <=> $b->{ln};
	return $cmp if $cmp;
    } elsif (exists($a->{ln})) {
	return -1;
    } elsif (exists($b->{ln})) {
	return 1;
    }
    return $a->{name} cmp $b->{name};
}

# Commits the accounts into /etc/passwd and /etc/shadow.  These files
# are sorted, so that existing accounts are left at the beginning of
# the file, and new accounts are added in lexicographical order. This
# way, the resulting file is less surprising to the reader.
sub commit_accounts
{
    my ($self, $accounts) = @_;

    $self->verbose("Committing passwd and shadow files");

    my (@passwd, @shadow, @ln, $fh);

    foreach my $cfg (sort accounts_sort (values(%$accounts))) {
      @ln =  ($cfg->{name}, 
              "x",
              $cfg->{uid},
      	      $cfg->{main_group},
      	      (exists($cfg->{comment}) ? $cfg->{comment} : ""),
      	      (exists($cfg->{homeDir}) ? $cfg->{homeDir} : ""),
      	      (exists($cfg->{shell}) ? $cfg->{shell} : "")
      	     );
      push(@passwd, join(":", @ln));
      @ln = ($cfg->{name},
             (defined($cfg->{password}) ? $cfg->{password} : "*"),
             15034, 0, 99999, 7, "", "", "");
      push(@shadow, join(":", @ln));
    }

    $self->info("Committing ", scalar(@passwd), " accounts");
    $fh = CAF::FileWriter->new(PASSWD_FILE, log => $self,
                               backup => ".old");
    print $fh join("\n", @passwd, "");
    $fh->close();
    $fh = CAF::FileWriter->new(SHADOW_FILE, log => $self,
                               backup => ".old",
                               mode => 0400);
    print $fh join("\n", @shadow, "");
    $fh->close();
}

# Returns a sanitized (untainted) version of the path given as an
# argument, or causes an error if the path is not valid.
sub sanitize_path
{
    my ($self, $path) = @_;

    if ($path !~ m{^(/[-\w\./]+)$}) {
        $self->error("Unsafe path: $path");
        return;
    }
    return $1;
}



# Creates the home directory of account $account, which should be
# configured with the provided $cfg.
sub create_home
{
    my ($self, $account, $cfg) = @_;

    my ($dir, $uid, $gid);
    $self->verbose("Creating home directory for $account at $cfg->{homeDir}");

    $dir = $self->sanitize_path($cfg->{homeDir}) or return;
    if ($cfg->{uid} !~ m{^(\d+)$}) {
	$self->error("Wrong uid for $account, not creating its home dir");
	return;
    }
    $uid = $1;

    if ($cfg->{main_group} !~ m{^(\d+)$}) {
	$self->error("Wrong group for $account, not creating its home dir");
	return;
    }
    $gid = $1;
    # Parent directories, if created, need to be readable by the new
    # user. The next step ensures the home directory is readable only
    # by the owner.
    if (!makedir($dir, 0755)) {
        $self->error("Failed to create home directory: $dir ",
                     "for account $account");
        return;
    }

    # Close the access while we copy everything from /etc/skel. This
    # step is needed, as the home directory might already exist.
    chown(0, 0, $dir);
    chmod(0700, $dir);

    my $find = LC::Find->new();
    $find->callback(
        sub {
            my $d = $self->sanitize_path("$dir/$LC::Find::SubDir") or return;
            my $f = $self->sanitize_path("$d/$LC::Find::Name") or return;
            my $src =  $self->sanitize_path(join("/", $LC::Find::TopDir,
                                                 $LC::Find::SubDir,
                                                 $LC::Find::Name)) or return;
            if (! -e $f) {
                if (-d $src) {
                    $self->verbose("Creating directory $f for $src");
                    if (!makedir($f, 0700)) {
                        $self->error("Couldn't create directory $f");
                        return;
                    }
                } else {
                    copy($src, $f, preserve => 1);
                }
            }
            chown($uid, $gid, $f);
        }
       );

    $find->find(SKELDIR);
    chown($uid, $gid, $dir);
}

# Builds all the home directories for any accounts miss itº and their
# createHome is true
sub build_home_dirs
{
    my ($self, $accounts) = @_;

    while (my ($account, $cfg) = each(%$accounts)) {
	if ($cfg->{createHome} && ! -d $cfg->{homeDir}) {
	    $self->create_home($account, $cfg);
	}
    }
}

sub commit_configuration
{
    my ($self, $system) = @_;

    $self->commit_groups($system->{groups});
    $self->commit_accounts($system->{passwd});
    $self->build_home_dirs($system->{passwd});
}

# Configure method
sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement(PATH)->getTree();

    my $system = $self->build_system_map($t->{login_defs});

    if ($t->{users}) {
	    $t->{users} = $self->compute_desired_accounts($t->{users});
    } else {
	    $t->{users} = {};
    }
    $t->{users}->{root} = $self->compute_root_user($system, $t);

    $self->adjust_groups($system, $t->{groups},  $t->{kept_groups},
			$t->{remove_unknown}, $t->{preserve_system_accounts});
    $self->adjust_accounts($system, $t->{users}, $t->{kept_users},
			   $t->{remove_unknown}, $t->{preserve_system_accounts});
    if (!$self->is_consistent($system)) {
	    $self->error("System would be inconsistent. ",
		     "Leaving without changing anything");
	    return 0;
    }
    if (!$NoAction) {
	    $self->commit_configuration($system);
    }

    return 1;
}

1;
