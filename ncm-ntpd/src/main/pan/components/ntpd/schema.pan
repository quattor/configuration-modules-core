${componentschema}

include 'quattor/types/component';
include 'pan/types';
include 'components/accounts/functions';

type ntpd_clientnet_type = {
    "net" : type_ip # Network of this machines NTP clients
    "mask" : type_ip # Netmask of this machines NTP clients
};

@documentation{
    Server command options
    Refer to man ntp.conf for details.
}
type ntpd_server_options = {
    "autokey" ? boolean
    "burst" ? boolean
    "iburst" ? boolean
    "key" ? long(1..655534)
    "minpoll" ? long(3..17)
    "maxpoll" ? long(3..17)
    "noselect" ? boolean
    "preempt" ? boolean
    "prefer" ? boolean
    "true" ? boolean
    "version" ? long(1..4)
};

@documentation{
    Base restrict command options
    Refer to C<< man ntp_acc >> for more information or access control commands.
}
type ntpd_restrict_options = {
    @{Mask can be a address of a host or network and can be a valid host DNS name.}
    "mask" ? type_ip
    "ignore" ? boolean = true
    "kod" ? boolean
    "limited" ? boolean
    "lowpriotrap" ? boolean
    "nomodify" ? boolean
    "noquery" ? boolean
    "nopeer" ? boolean
    "noserve" ? boolean
    "notrap" ? boolean
    "notrust" ? boolean
    "ntpport" ? boolean
    @{Deny packets that do not match the current NTP version.}
    "version" ? long(1..4)
};

@documentation{
    Default restrict command options.
    Default when none-defined: restrict default ignore.
}
type ntpd_restrict_default = ntpd_restrict_options;

@documentation{
    Server address with optional options and access restrictions
    Allows to configure timeservers with their own options.
}
type ntpd_server_definition = {
    @{Time server, can be ip address or qualified DNS hostname}
    "server" : type_hostname
    "options" ? ntpd_server_options
};

@documentation{
    Alter certain system variables used by the clock discipline algorithm
}
type ntpd_tinker_options = {
    "allan" ? long
    "dispersion" ? long
    "freq" ? long
    "huffpuff" ? long
    "panic" ? long
    "step" ? long
    "stepout" ? long
};

@documentation{
    System options that can be en/disabled.
    Flags not mentioned are unaffected.
    Note that all of these flags can be controlled remotely using
    the ntpdc utility program.
    Refer to ntp_misc manpage for more details.
}
type ntpd_system_options = {
    "auth" ? boolean
    "blient" ? boolean
    "calibrate" ? boolean
    "kernel" ? boolean
    "monitor" ? boolean
    "ntp" ? boolean
    "pps" ? boolean
    "stats" ? boolean
};

# logging configuration
function valid_ntpd_logconfig_list = {
    # Loop over each component.
    foreach (idx; configkeyword; ARGV[0]) {
        # all keywords can be prefixed with +-=
        if (!match(configkeyword, '^(\=|\-|\+)\w+')) {
            error("invalid logconfig value "
                + to_string(ARGV[0])
                + " all configkeywords must precede by +,-, or =");
        };
        configkeyword = substr("configkeyword", 1);
        if (!match(configkeyword, '^(all)?(clock|peer|sys|sync)?(status|events|statistics)?')) {
            error("invalid logconfig value "
                + to_string(ARGV[0])
                + " failed to match regex '" + match_logkw + "'");
        };
    };
    true;
};

@documentation{
    Log configuration arguments must be defined in a list of strings.
    Values for each argument must follow what is defined in ntp_misc manual.
    Refer to ntp_misc manpage for more details.

    Examples:
        to get command 'logconfig -syncstatus +sysevents'

        prefix "/software/components/ntpd";
        "logconfig" = list("-syncstatus", "+sysevents");
}
type ntpd_logconfig = string[] with valid_ntpd_logconfig_list(SELF);

@documentation{
    Monitoring/statistics options, see ntp_mon manpage.
}
type ntpd_statistics = {
    "clockstats" ? boolean
    "cryptostats" ? boolean
    "loopstats" ? boolean
    "peerstats" ? boolean
    "rawstats" ? boolean
    "sysstats" ? boolean
};

@documentation{
    Monitoring/statistics options, see ntp_mon manpage.
}
type ntpd_filegen = {
    "name" : string with match(SELF, '^(clock|crypto|loop|peer|raw|sys)stats$')
    "file" : string
    "type" ? string with match(SELF, '^(none|pid|day|week|month|year|age)$')
    "linkornolink" ? string with match(SELF, '^(no)?link$')
    "enableordisable" ? string with match(SELF, '^(en|dis)able$')
};

type ${project.artifactId}_component = {
    include structure_component
    @{Specifies the absolute path and of the MD5 key file containing the
      keys and key identifiers used by ntpd, ntpq and ntpdc when operating with
      symmetric key cryptography.
      Refer to ntp_auth manpage for more details.}
    "keyfile" ? absolute_file_path
    @{Refer to ntp_auth manpage for more details.
      Requires keyfile.}
    "trustedkey" ? long[]
    @{Specifies the key identifier to use with the ntpdc utility program.
      Refer to ntp_auth manpage for more details.
      Requires keyfile.}
    "requestkey" ? long
    @{Specifies the key identifier to use with the ntpq utility program.
      Refer to ntp_auth manpage for more details.
      Requires keyfile.}
    "controlkey" ? long
    @{Absolute path of the file used to record the frequency of the local clock oscillator.}
    "driftfile" ? absolute_file_path
    @{Additional configuration commands to be included from a separate file.}
    "includefile" ? absolute_file_path
    @{resolve and use the time server(s) ip address in the config file(s)}
    "useserverip" ? boolean
    "serverlist" ? ntpd_server_definition[]
    @{list of time servers (using defaultoptions)}
    "servers" ? type_hostname[]
    @{Specifies default command options for each timeserver defined in servers or serverlist.}
    "defaultoptions" ? ntpd_server_options
    @{List of clients that can use this server to synchronize. Default allows connections from localhost only.}
    "clientnetworks" ? ntpd_clientnet_type[]
    @{Absolute path to alternate logfile instead of default syslog. Refer to ntp_misc manpage for more details.}
    "logfile" ? absolute_file_path
    "logconfig" ? ntpd_logconfig
    @{Directory path prefix for statistics file names.}
    "statsdir" ? absolute_file_path
    "statistics" ? ntpd_statistics
    "filegen" ? ntpd_filegen[]
    @{Provides a way to disable various system options.}
    "disable" ? ntpd_system_options
    @{Provides a way to enable various system options.}
    "enable" ? ntpd_system_options
    "tinker" ? ntpd_tinker_options
    "restrictdefault" ? ntpd_restrict_default
    @{Double value in seconds to set network delay between local and remote servers.
      Refer to ntp_misc manpage for more details.}
    "broadcastdelay" ? double
    @{Adds string 'authenticate yes' to ntp.conf.}
    "authenticate" ? boolean
    @{Override the service name to restart. Some platforms
      use a different service name to represent ntpd.
      Defaults are "ntpd" on linux and "svc:/network/ntpd" on solaris.}
    "servicename" ? string
    @{Includes fudge options for localhost's clock. Defaults to true}
    "includelocalhost" ? boolean = true
    @{Allows some debugging via ntpdc on localhost but does not allow modifications. Defaults to true}
    "enablelocalhostdebug" ? boolean = true
    @{if the group is set, files are written with root.group ownership and 0640 permission}
    "group" ? defined_group
};
