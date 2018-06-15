# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/functions;

@{Given dict as first arg, test if exactly one of the remaining arguments is a key}
function openstack_oneof = {
    if (ARGC < 2) {
        error("%s: requires at least 2 arguments (%s given)", FUNCTION, ARGC);
    };

    data = ARGV[0];
    if (!is_dict(data)) {
        error("%s: first argumnet has to a dict, got value %s", FUNCTION, data);
    };

    found = false;

    for (idx = 1; idx < ARGC; idx = idx + 1) {
        if (exists(data[ARGV[idx]])) {
            if (found) {
                # found 2nd key
                return(false);
            } else {
                found = true;
            };
        };
    };

    found;
};

@{Test is name is a valid identity type. Name 'default' is always a valid name.}
function openstack_is_valid_identity = {
    if (ARGC != 2) {
        error("%s: requires at 2 arguments (name, type) (%s given)", FUNCTION, ARGC);
    };
    name = ARGV[0];

    is_string(name) && (
        name == 'default' ||
        exists(format("/software/components/openstack/identity/client/%s/%s", ARGV[1], name))
    );
};
