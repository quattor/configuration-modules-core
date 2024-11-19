declaration template components/network/types/network/backend/nmstate;

@{implement types specific for nmstate / nmstate.pm}

@documentation{
    NetworkManager device configuration for drop in config file.
}

type structure_nm_main_config = {
    @{Set the DNS processing mode for NetworkManager}
    "dns" : choice("default", "dnsmasq", "none", "systemd-resolved")
    @{Lists system settings plugin names}
    "plugins" ? choice('keyfile', 'ifcfg-rh')
    @{append a value to a previously-set list-valued}
    "plugins+" ? choice('keyfile', 'ifcfg-rh')
    @{remove a value to a previously-set list-valued}
    "plugins-" ? choice('keyfile', 'ifcfg-rh')
};

type structure_nm_device_config = {
    "keep-configuration" ? choice("yes", "no")
};

type structure_network_backend_specific = {
    @{let ncm-network cleanup inactive connections}
    "clean_inactive_conn" : boolean = true
    @{NetworkManager configuration settings for device section}
    "device_config" ? structure_nm_device_config
    @{NetworkManager configuration settings for main section}
    "main_config" : structure_nm_main_config
};

type structure_network_rule_backend_specific = {
    @{action used by nmstate module}
    "action" ? choice('blackhole', 'prohibit', 'unreachable')
    @{state used by nmstate module, Can only set to absent for deleting matching route rules}
    "state" ? choice('absent')
    @{iif used by nmstate module, Incoming interface name}
    "iif" ? string with path_exists(format('/system/network/interfaces/%s', SELF))
    @{fwmark used by nmstate module. Select the fwmark value to match}
    "fwmark" ? string(1..8) with match(SELF, '^[0-9a-f]{1,8}$')
    @{fwmask used by nmstate module. Select the fwmask value to match}
    "fwmask" ? string(1..8) with match(SELF, '^[0-9a-f]{1,8}$')
};

type structure_network_route_backend_specific = {
    @{congestion window size}
    "cwnd" ? long(10..)
    @{Initial congestion window size, applied to all sockets for the given targets.}
    "initcwnd" ? long(10..)
    @{Advertised receive window, applied to all sockets for the given targets.}
    "initrwnd" ? long(10..)
};

function network_valid_route = {
    if (exists(SELF['command'])) {
        if (length(SELF) != 1) error("Cannot use command and any of the other attributes as route");
    } else {
        if (!exists(SELF['address'])) error("Address is mandatory for route (in absence of command)");
        if (exists(SELF['prefix']) && exists(SELF['netmask'])) error("Use either prefix or netmask as route");
    };

    if (exists(SELF['gateway']) && exists(SELF['type'])) {
        error("The route gateway will be ignored when type is defined");
    };

    if (exists(SELF['prefix'])) {
        network_valid_prefix(SELF);
    };

    true;
};

function network_valid_rule = {
    if (!exists(SELF['command'])) {
        if (!exists(SELF['to']) && !exists(SELF['from'])) {
            error("Rule requires selector to or from (or use command)");
        };
    };
    true;
};
