# ${license-info}
# ${developer-info}
# ${author-info}

# File: sudo.pm
# Implementation of ncm-sudo
# Author: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# Version: 1.2.4 : 18/04/12 11:34
# Read carefully sudoers(5) man page before using this component!!
#
# Note: all methods in this component are called in a
# $self->$method ($config) way, unless explicitly stated.

package NCM::Component::sudo;

use strict;
use warnings;
use NCM::Component;
use CAF::FileWriter;
use CAF::Process;

use base qw(NCM::Component);
our $EC = LC::Exception::Context->new->will_store_all;
our $NoActionSupported = 1;

# Path for the sudoers file.
use constant FILE_PATH => '/etc/sudoers';
# PAN's path to this component.
use constant PROFILE_BASE => "/software/components/sudo/";
# PAN's paths to the component's fields.
use constant {
    USER_ALIASES     => PROFILE_BASE . "user_aliases",
    CMD_ALIASES      => PROFILE_BASE . "cmd_aliases",
    RUNAS_ALIASES    => PROFILE_BASE . "run_as_aliases",
    HOST_ALIASES     => PROFILE_BASE . "host_aliases",
    GENERAL_OPTS     => PROFILE_BASE . "general_options",
    PRIVILEGE_LINES  => PROFILE_BASE . "privilege_lines",
    PRIVILEGE_USER   => "user",
    PRIVILEGE_HOST   => "host",
    PRIVILEGE_RUNAS  => "run_as",
    PRIVILEGE_CMD    => "cmd",
    PRIVILEGE_OPTS   => "options",
    INCLUDES         => PROFILE_BASE . "includes",
    INCLUDES_DIRS    => PROFILE_BASE . "includes_dirs"
};

use constant VISUDO_CHECK => qw(/usr/sbin/visudo -c -f);
use constant VISUDO_STDIN_LINUX => '/proc/self/fd/0';
use constant VISUDO_STDIN_SOLARIS => '-';

# All possible "Default" options separated by type.
use constant BOOLEAN_OPTS => qw(
    long_otp_prompt
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
    visiblepw
);
use constant INT_OPTS => qw(
    passwd_tries
    loglinelen
    timestamp_timeout
    passwd_timeout
    umask
);
use constant STRING_OPTS => qw(
    mailsub
    env_keep
    env_delete
    badpass_message
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
    listpw
    secure_path
);

# generate_aliases method
#
# Returns a reference to a hash with user_aliases, host_aliases,
# run_as_aliases and cmd_aliases as read from its argument.  This will
# be transformed into a set of lines, but it is useful to have it this
# way for debugging.
sub generate_aliases {
    my ($self, $config) = @_;
    my $aliases = {
        USER_ALIASES()  => [],
        HOST_ALIASES()  => [],
        RUNAS_ALIASES() => [],
        CMD_ALIASES()   => []
    };

    foreach my $alias (USER_ALIASES, HOST_ALIASES, RUNAS_ALIASES, CMD_ALIASES) {
        next unless $config->elementExists ($alias);
        my $list = $config->getElement ($alias);
        next unless defined $list;
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
        } elsif (defined $def{PRIVILEGE_CMD ()}) {
            $ln = "!" . $def{PRIVILEGE_CMD ()}->getValue . "\t";
        } else {
            $ln = "\t";
        }
        my %opts = $def{PRIVILEGE_OPTS()}->getHash;
        foreach my $b (BOOLEAN_OPTS) {
            $ln .= ($opts{$b}->getValue eq 'true' ? '' : '!' ). "$b,"
                if (defined $opts{$b});
        }
        foreach my $o (INT_OPTS, STRING_OPTS) {
            $ln .= "$o=" . $opts{$o}->getValue . ","
                if defined $opts{$o};
        }
        $ln =~ s{[\s,]$}{};
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
        my %info = $el->getHash;
        my $ln = $info{PRIVILEGE_USER()}->getValue;
        $ln .= "\t" . $info{PRIVILEGE_HOST()}->getValue;
        $ln .= "= (". $info{PRIVILEGE_RUNAS()}->getValue . ")\t";
	if (defined($info{PRIVILEGE_OPTS()})) {
		$ln .= $info{PRIVILEGE_OPTS()}->getValue;
		$ln .= ':' if $ln !~ /:$/;
		$ln .= "\t";
	}
        $ln .= $info{PRIVILEGE_CMD()}->getValue;
        push (@$lns, $ln);
    }
    return $lns;
}

# Returns true if the contents of the file passed as an argument make
# a valid /etc/sudoers.
sub is_valid_sudoers {
    my ($self, $fh) = @_;
    my ($err, $out);

    my $proc = CAF::Process->new (
        [VISUDO_CHECK],
        stdin => "$fh",
        stderr => \$err,
        stdout => \$out,
        keeps_state => 1,
        log => $self
    );
    if ($^O eq "solaris") {
        $proc->pushargs(VISUDO_STDIN_SOLARIS);
    } else {
        $proc->pushargs(VISUDO_STDIN_LINUX);
    }
 
    $proc->execute();

    if ($? || $out !~ m{parsed OK}) {
        $self->error ("sudoers check said: $err");
        return 0;
    } else {
        $self->warn ($err) if $err;
    }
    return 1;
}

# write_sudoers method
#
# Writes all its arguments to the FILE_PATH file, with the sudoers
# format. Before actually writing, it checks that the contents of the
# new file are valid. If they are not, the new contents are discarded
# and the old file is kept.
#
# Arguments: ($_[0] = self!)
# $_[1]: a reference to a hash containing the aliases for users,
# run_as, hosts and commands.
# $_[2]: a reference to an array of default options lines.
# $_[3]: a reference to an array of privilege escalation lines
# $_[4]: a reference to an array of files to be directly included
# $_[5]: a reference to an array of directories with files to be
# directly included.
sub write_sudoers {
    my ($self, $aliases, $opts, $lns, $includes, $includes_dirs) = @_;

    my $fh = CAF::FileWriter->new (
        FILE_PATH,
        mode => 0440,
        owner => 0,
        group => 0,
        backup => '.old',
        log => $self
    );

    print $fh (
        "# File created by ncm-sudo v. ${project.version}\n",
        "# Read man(5) sudoers for understanding the structure\n",
        "# of this file\n"
    );

    print $fh ("\n# User alias specification\n");

    foreach my $alias (@{$aliases->{USER_ALIASES()}}) {
        printf $fh "%-15s %10s\n", "User_Alias", $alias;
    }

    print $fh "\n# Runas alias specification\n";
    foreach my $alias (@{$aliases->{RUNAS_ALIASES()}}) {
        printf $fh "%-15s %10s\n", "Runas_Alias", $alias;
    }

    print $fh "\n# Command alias specification\n";
    foreach my $alias (@{$aliases->{CMD_ALIASES()}}) {
        printf $fh "%-15s %10s\n", "Cmnd_Alias", $alias;
    }

    print $fh "\n# Host alias specification\n";
    foreach my $alias (@{$aliases->{HOST_ALIASES()}}) {
        printf $fh "%-15s %10s\n", "Host_Alias", $alias;
    }

    print $fh ("\n# Files to be included\n");
    foreach my $include (@$includes) {
        print $fh "#include $include\n";
    }

    print $fh "\n# Directories to be included\n";
    foreach my $include (@$includes_dirs) {
        print $fh "#includedir $include\n";
    }


    print $fh ("\n# Defaults specification\n");
    foreach my $opt ((@$opts)) {
        printf $fh "%s%s\n", "Defaults", $opt;
    }

    print $fh ("\n# User privilege specification\n");
    foreach my $line (@$lns) {
        print $fh "$line\n";
    }

    if (!$self->is_valid_sudoers($fh)) {
        $self->error("Invalid sudoers file. Not saving");
        $fh->cancel();
    }

    $fh->close();
    return 0;
}

# Generates the #include <filename> lines. Uses getTree because it was
# added later. The rest of the component should get adapted. Just not
# now.
sub generate_includes
{
    my ($self, $config, $path) = @_;

    if ($config->elementExists ($path)) {
        return $config->getElement ($path)->getTree();
    }
    return [];
}



# Configure method.
#
# Assume mandatory fields are there. You'll have to crash anyways if
# they're not present.
sub Configure {
        my ($self, $config) = @_;

        my $aliases = $self->generate_aliases ($config);
        my $opts = $self->generate_general_options ($config);
        my $incls = $self->generate_includes ($config, INCLUDES);
        my $incls_dirs = $self->generate_includes ($config, INCLUDES_DIRS);
        my $lns = $self->generate_privilege_lines ($config);

        return !$self->write_sudoers ($aliases, $opts, $lns, $incls, $incls_dirs);
}

1;
