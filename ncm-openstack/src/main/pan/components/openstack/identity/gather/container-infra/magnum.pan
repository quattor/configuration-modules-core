unique template components/openstack/identity/gather/container-infra/magnum;

@{openstack_quattor_magnum default value until we can use the schema defaults from value}
prefix "/software/components/openstack/container-infra/magnum/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 9511;
'suffix' ?= 'v1';
