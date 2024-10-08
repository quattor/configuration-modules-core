declaration template components/network/types/network;

include 'pan/types';
include 'quattor/functions/network';

final variable QUATTOR_TYPES_NETWORK_BACKEND ?= 'initscripts';

include format('components/network/types/network/backend/%s', QUATTOR_TYPES_NETWORK_BACKEND);

include 'components/network/types/network/interface';

@documentation{
    Define vip interfaces for configuring loopback interface. Used with frr/zebra configuration
}
type network_vip = {
    "interfaces" : valid_interface[]
    "ip"         : type_ip
    "fqdn"       ? type_fqdn
    "netmask"    ? type_ip
    "broadcast"  ? type_ip
};

@documentation{
    router
}
type network_router = string[];

@documentation{
    IPv6 global settings
}
type network_ipv6 = {
    "enabled" ? boolean
    "default_gateway" ? type_ip
    "gatewaydev" ? valid_interface # sets IPV6_DEFAULTDEV
};

@documentation{
    Host network configuration

    These values are used to generate /etc/sysconfig/network
    when using ncm-network (unless specified otherwise).
}
type structure_network = {
    include structure_network_backend_specific
    "domainname" : type_fqdn
    "hostname" : type_shorthostname
    "realhostname" ? string with is_shorthostname(SELF) || is_fqdn(SELF)
    "default_gateway" ? type_ip
    @{When default_gateway is not set, the component will try to guess the default
      gateway using the first configured gateway set on an interface.
      The default is true for backward compatible behaviour.}
    "guess_default_gateway" ? boolean
    "gatewaydev" ? valid_interface
    @{Per interface network settings.
      These values are used to generate the /etc/sysconfig/network-scripts/ifcfg-<interface> files
      when using ncm-network.}
    "interfaces" : network_interface{}
    "nameserver" ? type_ip[]
    "nisdomain" ? string(1..64) with match(SELF, '^\S+$')
    @{Setting nozeroconf to true stops an interface from being assigned an automatic address in the 169.254.0.0 subnet.}
    "nozeroconf" ? boolean
    @{The default behaviour for all interfaces wrt setting the MAC address (see interface set_hwaddr attribute).
      The component default is false.}
    "set_hwaddr" ? boolean
    "nmcontrolled" ? boolean
    "allow_nm" ? boolean
    "primary_ip" ? string
    "routers" ? network_router{}
    "ipv6" ? network_ipv6
    "manage_vips" : boolean = false
    "vips" ? network_vip{}
    @{Manage custom routing table entries; key is the name; value is the id}
    "routing_table" ? long(1..252){} with {
        if (exists(SELF['main']) || exists(SELF['local']) || exists(SELF['default']) || exists(SELF['unspec'])) {
            error("No reserved names in routing table");
        };
        true;
    }
} with {
    if (exists(SELF['default_gateway'])) {
        reachable = false;
        # is there any interface that can reach it?
        foreach (name; data; SELF['interfaces']) {
            if (exists(data['ip']) && exists(data['netmask']) &&
                ip_in_network(SELF['default_gateway'], data['ip'], data['netmask'])) {
                reachable = true;
            };
        };
        if (!reachable) {
            error("No interface with ip/mask found to reach default gateway");
        };
    };
    true;
};
