# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ntpd/schema;

include { 'quattor/schema' };

type ntpd_clientnet_type = {
    "net"  : type_ip # Network of this machines NTP clients
    "mask" : type_ip # Netmask of this machines NTP clients
};

type component_ntpd_type = {
    include structure_component
    "servers"           ? type_hostname[]
    "clientnetworks"    ? ntpd_clientnet_type[] # Optional list of client networks
};

bind "/software/components/ntpd" = component_ntpd_type;
