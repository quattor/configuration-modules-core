declaration template components/network/types/network/backend/initscripts;

@{implement types specific for initscripts / network.pm}

type structure_network_backend_specific = {
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
