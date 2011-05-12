# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/shorewall/schema;

include { 'quattor/schema' };

type component_shorewall_zones_zone = string;
type component_shorewall_zones_option = string with match(SELF,'');

type component_shorewall_zones = {
    "zone" : string
    "parent" ? component_shorewall_zones_zone[] 
    "type" : string with match(SELF, '(ipv4|ipsec|firewall|bport|-)')
    "options" ? component_shorewall_zones_option[] 
    "inoptions" ? component_shorewall_zones_option[] 
    "outoptions" ? component_shorewall_zones_option[]
};

type component_shorewall_interfaces_interface = string;

type component_shorewall_interfaces = {
    "zone" : component_shorewall_zones_zone 
    "interface" : component_shorewall_interfaces_interface
    "port" ? long(0..)
    "broadcast" ? string[]
    'options' ? string[] 
};

type component_shorewall_rules_action = string;

type component_shorewall_rules_srcdst = {
    ## zone: {zone|{all|any}[+][-]} $FW none
    "zone" : string 
    "interface" ? string
    ## this is an (mac)addres/range combo
    ## eg ~00-A0-C9-15-39-78,155.186.235.0/24!155.186.235.16/28
    "address" ? string[]
};

type component_shorewall_rules = {
    "action" : component_shorewall_rules_action
    "src" ? component_shorewall_rules_srcdst
    "dst" ? component_shorewall_rules_srcdst
    "proto" ? string 
    "dstport" ? string[] 
    "srcport" ? string[] 
    "origdst" ? string[] 
    "rate" ? string[] 
    "user" ? string
    "group" ? string
    "mark" ? string 
    "connlimit" ? string 
    "time" ? string 
};

type component_shorewall_shorewall = {
    "startup_enabled" : boolean
    ## no boolean
    "ip_forwarding" ? string with match(SELF,"(On|Off|Keep)")
};

type component_shorewall_type = {
    include structure_component
    "zones" : component_shorewall_zones[]
    "interfaces" : component_shorewall_interfaces[]
    "rules" : component_shorewall_rules[]
    "shorewall" : component_shorewall_shorewall
};

bind "/software/components/shorewall" = component_shorewall_type;
