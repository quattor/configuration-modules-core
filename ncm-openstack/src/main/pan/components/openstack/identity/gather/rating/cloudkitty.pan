unique template components/openstack/identity/gather/rating/cloudkitty;

@{openstack_quattor_cloudkitty default value until we can use the schema defaults from value}
prefix "/software/components/openstack/rating/cloudkitty/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8889;
'suffix' ?= '';
