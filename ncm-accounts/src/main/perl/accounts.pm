# ${license-info}
# ${developer-info}
# ${author-info}

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

# Pan path for the component configuration.
use constant PATH => "/software/components/accounts";

use constant PASSWD_FILE => "/etc/passwd";
use constant GROUP_FILE => "/etc/group";
use constant SHADOW_FILE => "/etc/shadow";
use constant LOGINDEFS_FILE => "/etc/login.defs";

# Default value for parameters defined in /etc/login.defs.
# These value are mainly used when creating new accounts: only parameters used by this component
# must have a value defined here. These values are not used to update /etc/login.defs.
# The key MUST match the login.defs parameter name.
use constant LOGINDEFS_DEFAULTS => {
        GID_MIN => 100,
        GID_MAX => 65535,
        UID_MIN => 100,
        UID_MAX => 65535,
        PASS_MIN_DAYS => 0,
        PASS_MAX_DAYS => 99999,
        PASS_WARN_AGE => 7,
};

# Mapping between configuration schema and /etc/login.defs keywords.
# One entry must exist for each login.defs keyword that is manageable
# through this component.  Key is a configuration property, value is
# the matching login.defs keyword.
use constant LOGINDEFS_MAPPING => {
        create_home => 'CREATE_HOME',
        gid_max => 'GID_MAX',
        gid_min => 'GID_MIN',
        mail_dir => 'MAIL_DIR',
        pass_max_days => 'PASS_MAX_DAYS',
        pass_min_days => 'PASS_MIN_DAYS',
        pass_min_len => 'PASS_MIN_LEN',
        pass_warn_age => 'PASS_WARN_AGE',
        uid_max => 'UID_MAX',
        uid_min => 'UID_MIN',
        umask => 'UMASK',
        userdel_cmd => 'USERDEL_CMD',
        usergroups_enab => 'USERGROUP_ENAB',
};

# Symbolic names for shadow fields
use constant PASSWORD_FIELD => 1;
use constant PASS_LAST_CHANGE => 2;
use constant PASS_MIN_DAYS => 3;
use constant PASS_MAX_DAYS => 4;
use constant PASS_WARN_AGE => 5;
use constant ACCOUNT_INACTIVE => 6;
use constant ACCOUNT_EXPIRATION => 7;

# Defaults for shadow fields if not defined in /etc/login.defs
use constant PASS_LAST_CHANGE_DEF => 15034;
use constant ACCOUNT_INACTIVE_DEF => "";
use constant ACCOUNT_EXPIRATION_DEF => "";

# Default groups for the root account.
use constant ROOT_DEFAULT_GROUPS => qw(root adm bin daemon sys disk);

use constant SKELDIR => "/etc/skel";

# Full path to nscd binary
use constant NSCD => '/usr/sbin/nscd';

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
      } else {
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

    my $ln = 1;
    while (my $l = <$fh>) {
      chomp($l);
      next unless $l;
      $self->debug(2, "Read group line $l");
      my @flds = split(":", $l);
      my $h = { name => $flds[NAME] };
      next unless $h->{name};
      if ( $h->{name} =~ /^\+/ ) {
        # Lines starting with a '+' are special lines to refer to NIS netgroup or LDAP groups
        # that can be used in passwd or shadow files. But they are invalid in group file.
        # It happens that some sites tend to add the same line in group file as in passwd file:
        # To avoid errors in the component, just discard those lines.
        $self->warn("line $ln in ".GROUP_FILE." is starting by '+': it'll be ignored as it is invalid.");
        next;
      } else {
        $h->{gid} = $flds[ID];
        my %mb;
        if ($flds[IDLIST]) {
            %mb = map(($_ => 1), split(",", $flds[IDLIST]));
        }
        $h->{members} = \%mb;
	$h->{ln} = $ln;
        $rt{$h->{name}} = $h;
      }
      $ln++;
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

    $rt{_passwd_special_lines_} = [];

    $ln = 0;
    while (my $l = <$fh>) {
      chomp($l);
      next unless $l;
      $self->debug(2, "Read line $l");
      my @flds = split(":", $l);
      my $h = { name => $flds[NAME] };
      next unless $h->{name};
      if ( $h->{name} =~ /^\+/ ) {
        # Lines starting with a '+' are special lines to refer to NIS
        # netgroup or LDAP groups.  Keep them unchanged. They will be
        # appended at the end of the passwd file.
        push(@{$rt{_passwd_special_lines_}}, $l);
      } else {
        $h->{uid} = $flds[ID];
        $h->{main_group} = $flds[IDLIST];
        $h->{homeDir} = $flds[HOME] || "";
        $h->{shell} = $flds[SHELL] || "";
        $h->{comment} = $flds[GCOS] || "";
        $h->{ln} = ++$ln;
        $rt{$h->{name}} = $h;
      }
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
    my ($self,$login_defs,$preserved_accounts) = @_;

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
      if ( exists(LOGINDEFS_MAPPING->{$p}) ) {
          my $k = LOGINDEFS_MAPPING->{$p};
          $rt{$k} = $v;
        $fh->add_or_replace_lines(qr/^\s*$k\s+/,
                                  qr/^\s*$k\s+$v\s*$/,
                                  "$k\t$v\n",
                                  ENDING_OF_FILE,
                                 );
        $self->debug(1, LOGINDEFS_FILE.": $k.set to $v");
      } else {
        $self->warn("No ".LOGINDEFS_FILE." matching keyword defined for login_defs/$p property (internal inconsistency)")
      }
    }

    # Define default value for missing parameters used by this component.
    # Do not update /etc/login.defs with these internal default values.
    while (my ($k,$v) = each(%{LOGINDEFS_DEFAULTS()})) {
      if ( !exists($rt{$k}) ) {
        $self->warn($k." not defined in ".LOGINDEFS_FILE.". Using default value (".$v.")");
        $rt{$k} = $v;
      }
    }

    # Define the maximum uid/gid to be preserved according to
    # $preserved_account value.
    #  - system: system range only must be preserved
    #  - dyn_user_group: up to GID/UID_MAX (included) must be preserved
    if ( $preserved_accounts eq 'system' ) {
      $rt{max_uid_preserved} = $rt{UID_MIN} - 1;
      $rt{max_gid_preserved} = $rt{GID_MIN} - 1;
    } elsif ( $preserved_accounts eq 'dyn_user_group' ) {
      $rt{max_uid_preserved} = $rt{UID_MAX};
      $rt{max_gid_preserved} = $rt{GID_MAX};
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

    $passwd->{_shadow_special_lines_} = [];

    while (my $l = <$fh>) {
        next unless $l;
        my @flds = split(":", $l);
        if ( $flds[NAME] =~ /^\+/ ) {
            # Lines starting with a '+' are special lines to refer to NIS netgroup or LDAP groups.
            # Keep them unchanged. They will be appended at the end of the shadow file.
            push(@{$passwd->{_shadow_special_lines_}}, $l);
        } elsif ( exists($passwd->{$flds[NAME]}) ) {
            $passwd->{$flds[NAME]}->{password} = $flds[PASSWORD_FIELD];
            $passwd->{$flds[NAME]}->{pass_min_days} = $flds[PASS_MIN_DAYS];
            $passwd->{$flds[NAME]}->{pass_max_days} = $flds[PASS_MAX_DAYS];
            $passwd->{$flds[NAME]}->{pass_warn_age} = $flds[PASS_WARN_AGE];
            $passwd->{$flds[NAME]}->{pass_last_change} = $flds[PASS_LAST_CHANGE];
            $passwd->{$flds[NAME]}->{inactive} = $flds[ACCOUNT_INACTIVE];
            $passwd->{$flds[NAME]}->{expiration} = $flds[ACCOUNT_EXPIRATION];
        } else {
            $self->debug(1,"Shadow entry ' ".$flds[NAME]."' ignored: no matching entry in password file");
        }
    }
}


# Returns three hash references: one for accounts, another one for
# groups, and the last one for shadow.
#
# Each member of each hash is a hash reference with a meaningful name
# for each field. If a field is a complex one (say, the list of
# members of a group, it will be a hash as well).
# In $passwd hash, there are 2 specific entries that must be moved off the hash:
# _passwd_special_lines_ and _shadow_special_lines. They refer to lines that must
# be kept as is.
sub build_system_map
{
    my ($self,$login_defs,$preserve_accounts) = @_;

    my $groups = $self->build_group_map();
    my $passwd = $self->build_passwd_map($groups);
    $self->add_shadow_info($passwd);
    my $logindefs = $self->build_login_defs_map($login_defs,$preserve_accounts);

    my $special_lines = {};
    $special_lines->{passwd} = $passwd->{_passwd_special_lines_};
    delete($passwd->{_passwd_special_lines_});
    $self->debug(1, scalar(@{$special_lines->{passwd}}),
                 " special lines found in ", PASSWD_FILE);
    $special_lines->{shadow} = $passwd->{_shadow_special_lines_};
    delete($passwd->{_shadow_special_lines_});
    $self->debug(1, scalar(@{$special_lines->{shadow}}),
                 " special lines found in ", SHADOW_FILE);

    $self->info(sprintf("System has %d accounts in %d groups",
                        scalar(keys(%$passwd)), scalar(keys(%$groups))));

    return { groups => $groups, passwd => $passwd, logindefs => $logindefs,
             special_lines => $special_lines};
}

# Deletes any groups in the $system not in the $profile, excepting
# those in the $kept list.
# Adjuss
sub delete_groups
{
    my ($self, $system, $profile, $kept, $preserve_groups) = @_;

    while (my ($group, $cfg) = each(%{$system->{groups}})) {
      if (!(exists($profile->{$group}) ||
            exists($kept->{$group}) ||
            ($preserve_groups) && ($cfg->{gid} <= $system->{logindefs}->{max_gid_preserved})
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
    my ($self, $system, $profile, $kept, $remove_unknown, $preserve_accounts) = @_;

    $self->verbose("Adjusting groups");

    $self->delete_groups($system, $profile, $kept, $preserve_accounts) if $remove_unknown;
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
          $self->error("Not found group $i for account $name. Skipping");
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
    my ($self, $system, $profile, $kept, $preserve_accounts) = @_;

    while (my ($account, $cfg) = each(%{$system->{passwd}})) {
      if (!(exists($profile->{$account}) ||
            exists($kept->{$account}) ||
            ($preserve_accounts) && ($cfg->{uid} <= $system->{logindefs}->{max_gid_preserved}) ||
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
        $self->debug(1, "Account $account exists in the system. ",
                        "Regenerating from the profile.");
        # Inherit from the existing account everything not specified in the profile.
        # This includes all the information in /etc/shadow for the account, including the password.
        while (my ($param,$v) = each(%{$system->{passwd}->{$account}})) {
          if (!exists($cfg->{$param})) {
            $self->debug(1, "Account $account inherits '$param' from the system");
            $cfg->{$param} = $v;
          }
        }
        # Also inherit the existing shell if it is an empty string in the profile.
        if (!$cfg->{shell}) {
          $self->debug(2, "Account $account: current shell preserved");
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
    my ($self, $system, $profile, $kept, $remove_unknown, $preserve_accounts) = @_;

    $self->verbose("Adjusting accounts");

    $self->delete_unneeded_accounts($system, $profile, $kept, $preserve_accounts)
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

    my $u = {uid => 0,
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

    foreach my $cfg (sort accounts_sort (values(%$groups))) {
	@ln =  ($cfg->{name},
		"x",
		$cfg->{gid},
		join(",", sort(keys(%{$cfg->{members}})))
	       );
	push(@group, join(":", @ln));
    }

    $self->info("Committing ", scalar(@group), " groups");

    $fh = CAF::FileWriter->new(GROUP_FILE, log => $self,
                               backup => ".old");
    print $fh join("\n", @group, "");
    $fh->close();

    $self->invalidate_cache('group');
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
    my ($self, $accounts, $special_lines, $login_defs) = @_;

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
             (defined($cfg->{pass_last_change}) ? $cfg->{pass_last_change} : PASS_LAST_CHANGE_DEF),
             (defined($cfg->{pass_min_days}) ? $cfg->{pass_min_days} : $login_defs->{PASS_MIN_DAYS}),
             (defined($cfg->{pass_max_days}) ? $cfg->{pass_max_days} : $login_defs->{PASS_MAX_DAYS}),
             (defined($cfg->{pass_warn_age}) ? $cfg->{pass_warn_age} : $login_defs->{PASS_WARN_AGE}),
             (defined($cfg->{inactive}) ? $cfg->{inactive} : ACCOUNT_INACTIVE_DEF),
             (defined($cfg->{expiration}) ? $cfg->{expiration} : ACCOUNT_EXPIRATION_DEF),
             ""
            );
      push(@shadow, join(":", @ln));
    }

    $self->info("Committing ", scalar(@passwd), " accounts");

    # Readd special lines if any at the end of passwd file
    push(@passwd, @{$special_lines->{passwd}});
    $fh = CAF::FileWriter->new(PASSWD_FILE, log => $self,
                               backup => ".old");
    print $fh join("\n", @passwd, "");
    $fh->close();

    # Readd special lines if any at the end of shadow file
    push(@shadow, @{$special_lines->{shadow}});
    $fh = CAF::FileWriter->new(SHADOW_FILE, log => $self,
                               backup => ".old",
                               mode => 0400);
    print $fh join("\n", @shadow, "");
    $fh->close();

    $self->invalidate_cache('passwd');
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
    $self->commit_accounts($system->{passwd}, $system->{special_lines},
                           $system->{logindefs});
    $self->build_home_dirs($system->{passwd});
}

sub invalidate_cache
{
    my ($self, $cache) = @_;

    $self->debug(1, "Preparing to invalidate cache: $cache");

    my $cmd_output;
    my $cmd_errors;
    my $command = [NSCD, '-i', $cache];

    if (-x NSCD) {
        my $pgrep = CAF::Process->new(['/usr/bin/pgrep', '-f', NSCD], log => $self,
                                      stdout => \$cmd_output,
                                      stderr => \$cmd_errors);
        $pgrep->execute();
        if ( $? == 0 ) {
            my $cmd = CAF::Process->new($command, log => $self,
                                        stdout => \$cmd_output,
                                        stderr => \$cmd_errors);
            $cmd->execute();
            if ( $? == 0 ) {
                $self->info("Invalidated nscd cache");
            } else {
                $self->error("Invalidating cache failed");
            }
        } else {
            $self->debug(1, "nscd found but not running, will not invalidate cache.");
        }
    } else {
        $self->debug(1, "nscd not found, will not do anything.");
    }
}

# Configure method
sub Configure
{
    my ($self, $config) = @_;

    my $t = $config->getElement(PATH)->getTree();
    my $preserve_accounts = 0;
    if ( $t->{preserved_accounts} ne 'none' ) {
      $preserve_accounts = 1;
    }

    my $system = $self->build_system_map($t->{login_defs},$t->{preserved_accounts});

    if ($t->{users}) {
          $t->{users} = $self->compute_desired_accounts($t->{users});
    } else {
          $t->{users} = {};
    }
    $t->{users}->{root} = $self->compute_root_user($system, $t);

    $self->adjust_groups($system, $t->{groups},  $t->{kept_groups},
                         $t->{remove_unknown}, $preserve_accounts);
    $self->adjust_accounts($system, $t->{users}, $t->{kept_users},
                           $t->{remove_unknown}, $preserve_accounts);
    if (!$self->is_consistent($system)) {
          $self->error("System would be inconsistent. ",
                       "Leaving without changing anything");
          return 0;
    }
    $self->commit_configuration($system);

    return 1;
}

1;
