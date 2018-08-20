unique template components/openstack/identity/gather/compute/nova;

@{openstack_quattor_nova default value until we can use the schema defaults from value}
prefix "/software/components/openstack/compute/nova/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8774;
'suffix' ?= '%(tenant_id)s';

prefix "services/placement";
"type" = "placement";
"internal/port" ?= 8778;
"internal/suffix" ?= '';
