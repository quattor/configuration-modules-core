# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/iscsitarget/schema;

# ???
#include { 'pan/structures' };

include { 'quattor/schema' };

type component_iscsitarget_element_type = {
    "device_path" ? string # "relative/to/system/blockdevices"
    "authentication_type" ? string # "(none|chap) defaults to none"
	"authentication_resource" ? string # "/etc/iscsi.passwd"
	"initiators" ? string[] # list( "192.168.77.0/24",....), default: anyone 
};

# FIXME enforce constraints
type component_iscsitarget_type = {
    include structure_component
	"targets" ? component_iscsitarget_element_type[]
};

bind "/software/components/iscsitarget" = component_iscsitarget_type;


# /software/components/iscsi-target/
#	+-"_0"
#	$ device_path: "relative/to/system/blockdevices"
#	$ authentication_type: (none|chap)
#	$ authentication_resource: "/etc/iscsi.passwd"
#	+-initiators: list( "192.168.77.0/24",....) # default: anyone on eth1?  optional

