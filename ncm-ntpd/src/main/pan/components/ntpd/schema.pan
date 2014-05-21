# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

type ntpd_clientnet_type = {
    "net"  : type_ip # Network of this machines NTP clients
    "mask" : type_ip # Netmask of this machines NTP clients
};

# base server command options
type ntpd_server_options = extensible {
    "autokey"  ? boolean
    "burst"    ? boolean
    "iburst"   ? boolean
    "key"      ? long(1..655534)
    "minpoll"  ? long(3..17)
    "maxpoll"  ? long(3..17)
    "noselect" ? boolean
    "preempt"  ? boolean
    "prefer"   ? boolean
    "true"     ? boolean
    "version"  ? long(1..4)
};

# base restrict command options
type ntpd_restrict_options = extensible {
    "mask"        ? type_ip
    "ignore"      ? boolean = true
    "kod"         ? boolean
    "limited"     ? boolean
    "lowpriotrap" ? boolean
    "nomodify"    ? boolean
    "noquery"     ? boolean
    "nopeer"      ? boolean
    "noserve"     ? boolean
    "notrap"      ? boolean
    "notrust"     ? boolean
    "ntpport"     ? boolean
    "version"     ? long(1..4)
};

# restrict default
type ntpd_restrict_default = ntpd_restrict_options;

# structure server address with optional options and access restrictions
type ntpd_server_definition = {
    "server"  : type_hostname
    "options"  ? ntpd_server_options
};

# toggle system options
type ntpd_tinker_options = {
    "allan"      ? long
    "dispersion" ? long
    "freq"       ? long
    "huffpuff"   ? long
    "panic"      ? long
    "step"       ? long
    "stepout"    ? long
};

type ntpd_system_options = {
    "auth"       ? boolean
    "blient"     ? boolean
    "calibrate"  ? boolean
    "kernel"     ? boolean
    "monitor"    ? boolean
    "ntp"        ? boolean
    "pps"        ? boolean
    "stats"      ? boolean
};

type ntpd_disable_options = ntpd_system_options;
type ntpd_enable_options = ntpd_system_options;

# logging configuration
function valid_ntpd_logconfig_list = {
    # Loop over each component.
    foreach (idx; configkeyword; ARGV[0]) {
        # all keywords can be prefixed with +-=
        if (!match(configkeyword,'^(\=|\-|\+)\w+')) {
            error("invalid logconfig value "
                + to_string(ARGV[0])
                + " all configkeywords must precede by +,-, or =");
        };
        configkeyword = substr("configkeyword",1);
        if (!match(configkeyword,'^(all)?(clock|peer|sys|sync)?(status|events|statistics)?')) {
            error("invalid logconfig value "
                + to_string(ARGV[0])
                + " failed to match regex '" + match_logkw + "'");
        };
    };
    true;
};

type ntpd_logconfig = string[] with valid_ntpd_logconfig_list(SELF);

# monitoring options,  see man ntp_mon
type ntpd_statistics = {
    "clockstats"  ? boolean
    "cryptostats" ? boolean
    "loopstats"   ? boolean
    "peerstats"   ? boolean
    "rawstats"    ? boolean
    "sysstats"    ? boolean
};

type ntpd_filegen_name = string
    with match(SELF, 'clockstats|cryptostats|loopstats|peerstats|rawstats|sysstats');

type ntpd_filegen = {
    "name"            : ntpd_filegen_name
    "file"            : string
    "type"            ? string with match(SELF, 'none|pid|day|week|month|year|age')
    "linkornolink"    ? string with match(SELF, 'link|nolink')
    "enableordisable" ? string with match(SELF, 'enable|disable')
};

type component_ntpd_type = extensible  {
    include structure_component
    "keyfile"                 ? string
    "trustedkey"              ? long[]
    "requestkey"              ? long
    "controlkey"              ? long
    "driftfile"               ? string
    "includefile"             ? string
    "servers"                 ? type_hostname[]
    "defaultoptions"          ? ntpd_server_options
    "clientnetworks"          ? ntpd_clientnet_type[]
    "logfile"                 ? string
    "logconfig"               ? ntpd_logconfig
    "statsdir"                ? string
    "statistics"              ? ntpd_statistics
    "filegen"                 ? ntpd_filegen[]
    "disable"                 ? ntpd_disable_options
    "enable"                  ? ntpd_enable_options
    "tinker"                  ? ntpd_tinker_options
    "serverlist"              ? ntpd_server_definition[]
    "restrictdefault"         ? ntpd_restrict_default
    "broadcastdelay"          ? double
    "authenticate"            ? boolean
    "servicename"             ? string
    "includelocalhost"        ? boolean = true
    "enablelocalhostdebug"    ? boolean = true
};

bind "/software/components/ntpd" = component_ntpd_type;
