# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ipmi/schema;

include 'quattor/schema';

type structure_users = {
    "login" : string
    "password" : string
    "priv" ? string
    "userid" ? long
};

type component_ipmi_type = {
    include structure_component

    "channel" : long = 1
    "users" : structure_users[]
    "net_interface" : string
};

bind "/software/components/ipmi" = component_ipmi_type;

