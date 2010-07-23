# ${license-info}
# ${developer-info}
# ${author-info}

# File: sudo.pm
# Implementation of ncm-sudo
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 1.1.9 : 23/07/10 13:38
# Read carefully sudoers(5) man page before using this component!!
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::sudo;


use strict;
use warnings;
use NCM::Component;
use EDG::WP4::CCM::Element;
use EDG::WP4::CCM::Resource;
use EDG::WP4::CCM::Property;
use NCM::Check;
use FileHandle;

our @ISA = qw (NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;

# Path for the sudoers file.
use constant FILE_PATH		=> '/etc/sudoers';
# PAN's path to this component.
use constant PROFILE_BASE	=> "/software/components/sudo/";
# PAN's paths to the component's fields.
use constant { USER_ALIASES	=> PROFILE_BASE . "user_aliases",
	       CMD_ALIASES	=> PROFILE_BASE . "cmd_aliases",
	       RUNAS_ALIASES	=> PROFILE_BASE . "run_as_aliases",
	       HOST_ALIASES	=> PROFILE_BASE . "host_aliases",
	       GENERAL_OPTS	=> PROFILE_BASE . "general_options",
	       PRIVILEGE_LINES	=> PROFILE_BASE . "privilege_lines",
	       PRIVILEGE_USER	=> "user",
	       PRIVILEGE_HOST	=> "host",
	       PRIVILEGE_RUNAS	=> "run_as",
	       PRIVILEGE_CMD	=> "cmd",
	       PRIVILEGE_OPTS	=> "options"
       };

# All possible "Default" options separated by type.
use constant BOOLEAN_OPTS	=> qw(long_otp_prompt
				      ignore_dot
				      mail_always
				      mail_badpass
				      mail_no_user
				      mail_no_host
				      mail_no_perms
				      tty_tickets
				      lecture
				      authenticate
				      root_sudo
				      log_host
				      log_year
				      shell_noargs
				      set_home
				      always_set_home
				      path_info
				      preserve_groups
				      fqdn
				      insults
				      requiretty
				      env_editor
				      rootpw
				      runaspw
				      targetpw
				      set_logname
				      stay_setuid
				      env_reset
				      use_loginclass
				      );
use constant INT_OPTS		=> qw(passwd_tries
				    loglinelen
				    timestamp_timeout
				    passwd_timeout
				    umask
				    );
use constant STRING_OPTS	=> qw(badpass_message
                    env_keep
                    env_delete
                    timestampdir
				    timestampowner
				    passprompt
				    runas_default
				    syslog_goodpri
				    syslog_badpri
				    editor
				    logfile
				    syslog
				    mailerpath
				    mailerflags
				    mailto
				    exempt_group
				    verifypw
				    listpw);

# generate_aliases method
#
# Returns a reference to a hash with user_aliases, host_aliases,
# run_as_aliases and cmd_aliases as read from its argument.  This will
# be transformed into a set of lines, but it is useful to have it this
# way for debugging.
sub generate_aliases {
	my ($self, $config) = @_;
	my $aliases = { USER_ALIASES()	=> [],
			HOST_ALIASES()	=> [],
			RUNAS_ALIASES()	=> [],
			CMD_ALIASES()	=> []
		      };

	foreach my $alias (USER_ALIASES, HOST_ALIASES, RUNAS_ALIASES,
			   CMD_ALIASES) {
		next unless $config->elementExists ($alias);
		my $list = $config->getElement ($alias);
		next unless defined $list;
		$self->debug (5, "Alias list: $alias\tList\t$list");
		while ($list->hasNextElement) {
			my $lm = $list->getNextElement;
			my $ln = $lm->getName;
			$ln .= "\t= ";
			$ln .= $lm->getNextElement->getValue . ","
			while $lm->hasNextElement;
			chop $ln;
			push (@{$$aliases{$alias}}, $ln);
		}
	}
	$self->debug (5, %$aliases);
	return $aliases;
}

# generate_general_options method
#
# Returns a reference to an array of strings each containing one
# "Default" line.
sub generate_general_options {

	my ($self, $config) = @_;
	my $dfl = [];

	return unless $config->elementExists (GENERAL_OPTS);

	my $lst = $config->getElement (GENERAL_OPTS);

	while ($lst->hasNextElement) {
		my $el = $lst->getNextElement;
		my %def = $el->getHash;
		my $ln;
		# Only one of "user", "run_as" or "host" may be defined!!
		if (defined $def{PRIVILEGE_USER()}) {
			$ln = ":" . $def{PRIVILEGE_USER()}->getValue . "\t";
		} elsif (defined $def{PRIVILEGE_RUNAS()}) {
			$ln = ">" . $def{PRIVILEGE_RUNAS()}->getValue . "\t";
		} elsif (defined $def{PRIVILEGE_HOST ()}) {
			$ln = "@" . $def{PRIVILEGE_HOST ()}->getValue . "\t";
		} else {
			$ln = "\t";
		}
		my %opts = $def{PRIVILEGE_OPTS()}->getHash;
		foreach (BOOLEAN_OPTS) {
			if (defined $opts{$_}) {
				if ($opts{$_}->getValue eq 'true') {
					$ln .= "$_\t";
				} else {
					$ln .= "!$_\t";
				}
			}
		}
		foreach (INT_OPTS, STRING_OPTS) {
			$ln .= "$_=" . $opts{$_}->getValue . "\t"
			if defined $opts{$_};
		}
		$ln =~ s{\t$}{};
		push (@$dfl, $ln);
	}
	return $dfl;
}

# generate_privilege_lines method
#
# Returns a reference to an array of strings, each containing one
# complete privilege escalation line.
sub generate_privilege_lines {
	my ($self, $config) = @_;
	my $lns = [];

	# Privilege lines are mandatory.
	my $list = $config->getElement (PRIVILEGE_LINES);
	while ($list->hasNextElement) {
		my $el = $list->getNextElement;
		$self->debug (1, $el->getPath);
		my %info = $el->getHash;
		my $ln = $info{PRIVILEGE_USER()}->getValue;
		$ln .= "\t" . $info{PRIVILEGE_HOST()}->getValue;
		$ln .= "= (". $info{PRIVILEGE_RUNAS()}->getValue . ")\t";
		$ln .= $info{PRIVILEGE_OPTS()}->getValue . ":\t"
		if defined $info{PRIVILEGE_OPTS()};
		$ln .= $info{PRIVILEGE_CMD()}->getValue;
		push (@$lns, $ln);
		$self->debug (5, %info);
	}
	return $lns;
}

# write_sudoers method
#
# Writes all its arguments to the FILE_PATH file, with the sudoers
# format.
# Arguments: ($_[0] = self!)
# $_[1]: a reference to a hash containing the aliases for users,
# run_as, hosts and commands.
# $_[2]: a reference to an array of default options lines.
# $_[3]: a reference to an array of privilege escalation lines
sub write_sudoers {
	my ($self, $aliases, $opts, $lns) = @_;
	my $fh = FileHandle->new (FILE_PATH, "w");
	unless ($fh) {
		$self->error ("Couldn't open " . FILE_PATH);
		return;
	}
	$fh->print ("# File created by ncm-sudo v. 1.1.9\n",
		    "# Report bugs to CERN's savannah\n".
		    "# Read man(5) sudoers for understanding the structure ".
		    "of this file\n");

    $fh->print ("\n# User alias specification\n");
	$fh->print ("User_Alias\t", $_, "\n") foreach (@{${$aliases}
							 {USER_ALIASES()}});
    $fh->print ("\n# Runas alias specification\n");
	$fh->print ("Runas_Alias\t", $_, "\n") foreach (@{${$aliases}
							  {RUNAS_ALIASES()}});
    $fh->print ("\n# Cmnd alias specification\n");
	$fh->print ("Cmnd_Alias\t", $_, "\n") foreach (@{${$aliases}
							 {CMD_ALIASES()}});
    $fh->print ("\n# Host alias specification\n");
	$fh->print ("Host_Alias\t", $_, "\n") foreach (@{${$aliases}
							 {HOST_ALIASES()}});
    $fh->print ("\n# Defaults specification\n");
	$fh->print ("Defaults", $_, "\n") foreach (@$opts);
    $fh->print ("\n# User privilege specification\n");
	$fh->print ("$_\n") foreach (@$lns);
	$fh->close;
	return 0;
}

# Configure method.
#
# Assume mandatory fields are there. You'll have to crash anyways if
# they're not present.
sub Configure {
	my ($self, $config) = @_;

	my $aliases = $self->generate_aliases ($config);
	my $opts = $self->generate_general_options ($config);
	my $lns = $self->generate_privilege_lines ($config);

	return !$self->write_sudoers ($aliases, $opts, $lns);

}
