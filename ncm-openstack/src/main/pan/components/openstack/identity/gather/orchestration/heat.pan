unique template components/openstack/identity/gather/orchestration/heat;

@{openstack_quattor_heat default value until we can use the schema defaults from value}
prefix "/software/components/openstack/orchestration/heat/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8004;
'suffix' ?= 'v1/%(tenant_id)s';

prefix "services/heat-cfn";
"type" = "cloudformation";
"internal/port" ?= 8000;
"internal/suffix" ?= 'v1';
