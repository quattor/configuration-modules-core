unique template components/openstack/identity/gather/share/manila;

@{openstack_quattor_manila default value until we can use the schema defaults from value}
prefix "/software/components/openstack/share/manila/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8786;
'suffix' ?= 'v1/%(tenant_id)s';

prefix "services/manilav2";
"type" = "sharev2";
"internal/port" ?= 8786;
"internal/suffix" ?= 'v2/%(tenant_id)s';
