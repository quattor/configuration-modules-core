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
};

@documentation{
    desc = Check if a list of service names does not contain illegal characters.
    arg = List of service names.
}
function icinga_check_service_name = {
    v = ARGV[0];
    foreach(key; val; v) {
        if (! match (unescape(key), '^[\w. -]+$')) {
            error(format('Icinga service name "%s" contains invalid characters.', unescape(key)));
        };
    };
    true;
};
