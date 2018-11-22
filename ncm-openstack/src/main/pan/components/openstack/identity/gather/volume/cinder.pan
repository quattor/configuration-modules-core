unique template components/openstack/identity/gather/volume/cinder;

@{openstack_quattor_cinder default value until we can use the schema defaults from value}
prefix "/software/components/openstack/volume/cinder/quattor";
'service/name' = 'cinderv2';
'service/type' = 'volumev2';
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8776;
'suffix' ?= 'v2/%(project_id)s';

prefix "services/cinderv3";
"type" = "volumev3";
"internal/port" ?= 8776;
"internal/suffix" ?= 'v3/%(project_id)s';
