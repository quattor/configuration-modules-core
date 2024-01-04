declaration template components/network/types/network/backend/initscripts;

@{implement types specific for initscripts / network.pm}

type structure_network_backend_specific = {
};

type structure_network_rule_backend_specific = {
};

function network_valid_route = {
    if (exists(SELF['prefix']) && exists(SELF['netmask'])) {
        error("Use either prefix or netmask as route");
    };

    if (exists(SELF['prefix'])) {
        network_valid_prefix(SELF);
    };

    true;
};

function network_valid_rule = {
    if (exists(SELF['command'])) {
        if (length(SELF) != 1) error("Cannot use command and any of the other attributes as rule");
    } else {
        if (!exists(SELF['to']) && !exists(SELF['from'])) {
            error("Rule requires selector to or from (or use command)");
        };
        if (!exists(SELF['table'])) {
            error("Rule requires action table (or use command)");
        };
    };
    true;
};
