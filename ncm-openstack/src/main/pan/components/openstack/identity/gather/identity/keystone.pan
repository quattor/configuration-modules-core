unique template components/openstack/identity/gather/identity/keystone;

@{openstack_quattor_keystone default value until we can use the schema defaults from value}
prefix "/software/components/openstack/identity/keystone/quattor/service";
prefix "internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 5000;
'suffix' ?= 'v3';

prefix "admin";
"port" ?= 35357;
