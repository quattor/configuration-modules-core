${componentschema}

include 'quattor/types/component';
include 'pan/types';

@{a valid hostname, possibly preceeded by an '!'}
type sudo_host = string with {
    is_network_name(SELF) ||
    (substr(SELF, 0, 1) == '!' &&
    is_network_name(substr(SELF, 1)));
};

type sudo_user_alias = string[];
type sudo_cmd_alias = string[];
type sudo_host_alias = sudo_host[];

type sudo_privilege_line = {
    @{User invoking sudo}
    "user" : string
    @{User the program will run under}
    "run_as" : string
    @{host the command can be run from}
    "host" : string
    @{Specific options for this command}
    "options" ? string with match (SELF,
        "^((NOPASSWD|PASSWD|NOEXEC|EXEC|SETENV|NOSETENV|LOG_INPUT|NOLOG_INPUT|LOG_OUTPUT|NOLOG_OUTPUT):?)+$")
    @{The command being run}
    "cmd" : string
};

# This is an awful structure, but this is all the power sudo can give!
@{Can have any of the documented atomic (non-list!!) values for the
  Defaults section in man(5) sudoers}
type sudo_default_options = {
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
};

@{sudo defaults, i.e. an optional user,
  an optional host, an optional run_as user (to be supplanted)
  And a set of default settings.}
type sudo_defaults = {
    "user" ? string
    "run_as" ? string
    "host" ? sudo_host
    "cmd" ? string
    "options" : sudo_default_options
};

@{Configuration for the sudoers.ldap}
type sudo_ldap = {
    "dn" : string
    "objectClass" ? string[]
    "sudoOption" ? sudo_default_options
    "description" : string
    "sudoUser" : string[]
    "sudoRunAsUser" : string[] = list("ALL")
    "sudoHost" : string[] = list("ALL")
    "sudoCommand" : string[] = list("ALL")
};


@{Structure for the component. See man sudoers for information on user_aliases,
  host_aliases, run_as_aliases and cmd_aliases
  All alias names must be in capitals.}
type sudo_component = {
    include structure_component
    "general_options" ? sudo_defaults[]
    "user_aliases" ? sudo_user_alias {}
    "run_as_aliases" ? sudo_user_alias {}
    "host_aliases" ? sudo_host_alias {}
    "cmd_aliases" ? sudo_cmd_alias  {}
    "privilege_lines" ? sudo_privilege_line[]
    "includes" ? string[]
    "includes_dirs" ? string[]
    "ldap" ? sudo_ldap
};
