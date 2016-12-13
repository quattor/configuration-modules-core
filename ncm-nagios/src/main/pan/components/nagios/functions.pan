# ${license-info}
# ${developer-info}
# ${author-info}

template components/nagios/functions;

function nagios_has_host_or_hostgroup = {
    v = ARGV[0];
    if (exists (v["host_name"]) || exists (v["hostgroup_name"])) {
        return (true);
    };
    error ("At least one of host_name or hostgroup_name must be defined");
    return (false);
};
