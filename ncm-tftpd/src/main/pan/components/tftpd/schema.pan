# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/tftpd/schema;

include {'quattor/schema'};

type component_tftpd_type = {
    include structure_component
    "disable"       : string with match (SELF, 'yes|no')
    "wait"          : string with match (SELF, 'yes|no')
    "user"          : string
    "server"        :  string
    "server_args"   : string
};

bind "/software/components/tftpd" = component_tftpd_type;
