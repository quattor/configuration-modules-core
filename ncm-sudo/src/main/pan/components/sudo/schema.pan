# ${license-info}
# ${developer-info}
# ${author-info}

# Data structures modelling the whole sudo behaviour.
# See ncm-sudo man page for more details.

declaration template components/sudo/schema;

include 'quattor/schema';

function is_host_sudo = {
    if (ARGC != 1 || !is_string (ARGV[0])) {
    error ("usage: is_host_sudo(string)");
    };
    if (is_network_name (ARGV[0])) {
    return (true);
    };
    bg = substr (ARGV[0], 0, 1);
    rs = substr (ARGV[0], 1);

    return (bg=="!" && is_network_name(rs));
};

type type_host_sudo = string with {
    is_host_sudo (SELF);
};

type type_user_alias = string[];
type type_cmd_alias = string[];
type type_host_alias = type_host_sudo[];

type structure_privilege_line = {
    "user" : string        # "User invoking sudo"
    "run_as" : string        # "User the program will run under"
    "host" : string        # "host the command can be run from"
    "options" ? string        with match (SELF, "^((NOPASSWD|PASSWD|NOEXEC|EXEC|SETENV|NOSETENV|LOG_INPUT|NOLOG_INPUT|LOG_OUTPUT|NOLOG_OUTPUT):?)+$")
    # "Specific options for this command"
    "cmd" : string        # "The command being run"
};

# This is an awful structure, but this is all the power sudo can give!
# See man sudoers for full explanations
type structure_sudo_default_options = {
    "long_otp_prompt" ? boolean
    "ignore_dot" ? boolean
    "mail_always" ? boolean
    "mail_badpass" ? boolean
    "mail_no_user" ? boolean
    "mail_no_host" ? boolean
    "mail_no_perms" ? boolean
    "tty_tickets" ? boolean
    "lecture" ? boolean
    "authenticate" ? boolean
    "root_sudo" ? boolean
    "log_host" ? boolean
    "log_year" ? boolean
    "shell_noargs" ? boolean
    "set_home" ? boolean
    "always_set_home" ? boolean
    "path_info" ? boolean
    "preserve_groups" ? boolean
    "fqdn" ? boolean
    "insults" ? boolean # This should always be true!!
    "requiretty" ? boolean
    "env_editor" ? boolean
    "rootpw" ? boolean
    "runaspw" ? boolean
    "targetpw" ? boolean
    "set_logname" ? boolean
    "stay_setuid" ? boolean
    "env_reset" ? boolean
    "use_loginclass" ? boolean
    "visiblepw" ? boolean
    "passwd_tries" ? long
    "loglinelen" ? long
    "timestamp_timeout" ? long
    "passwd_timeout" ? long
    "umask" ? long
    "mailsub" ? string
    "env_keep" ? string
    "env_delete" ? string
    "badpass_message" ? string
    "timestampdir" ? string
    "timestampowner" ? string
    "passprompt" ? string
    "runas_default" ? string
    "syslog_goodpri" ? string
    "syslog_badpri" ? string
    "editor" ? string
    "logfile" ? string
    "syslog" ? string
    "mailerpath" ? string
    "mailerflags" ? string
    "mailto" ? string
    "exempt_group" ? string
    "verifypw" ? string
    "listpw" ? string
    "secure_path" ? string
    # List syntax would be too complex for this purposes! Will be
    # added just under request.
};


# Structure for sudo defaults, I.E: an optional user,
# an optional host, an optional run_as user (to be supplanted)
# And a set of default settings.
type structure_sudo_defaults = {
    "user" ? string
    "run_as" ? string
    "host" ? type_host_sudo
    "cmd" ? string
    "options" : structure_sudo_default_options
};

# Configuration for the sudoers.ldap
type structure_sudo_ldap = {
    "dn" : string
    "objectClass" ? string[]
    "sudoOption" ? structure_sudo_default_options
    "description" : string
    "sudoUser" : string[]
    "sudoRunAsUser" : string[] = list("ALL")
    "sudoHost" : string[] = list("ALL")
    "sudoCommand" : string[] = list("ALL")
};


# Structure for the component. See man sudoers for information on user_aliases,
# host_aliases, run_as_aliases and cmd_aliases
# All alias names must be in capitals.
# See https://twiki.cern.ch/twiki/bin/view/ELFms/NCMAccessControlReplacement#NCM_sudo_component
# for more detailed description.
type structure_component_sudo = {
    include structure_component
    "general_options" ? structure_sudo_defaults[]
    "user_aliases" ? type_user_alias {}
    "run_as_aliases" ? type_user_alias {}
    "host_aliases" ? type_host_alias {}
    "cmd_aliases" ? type_cmd_alias  {}
    "privilege_lines" ? structure_privilege_line[]
    "includes" ? string[]
    "includes_dirs" ? string[]
    "ldap" ? structure_sudo_ldap
};

bind "/software/components/sudo" = structure_component_sudo;
