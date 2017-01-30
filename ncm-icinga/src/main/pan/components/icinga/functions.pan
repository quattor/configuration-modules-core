# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

template components/icinga/functions;

function icinga_has_host_or_hostgroup = {
    v = ARGV[0];
    if (exists (v["host_name"]) || exists (v["hostgroup_name"])) {
        return (true);
    };
    error ("At least one of host_name or hostgroup_name must be defined");
    return (false);
};
