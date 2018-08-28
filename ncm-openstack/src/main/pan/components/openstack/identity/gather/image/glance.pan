unique template components/openstack/identity/gather/image/glance;

@{openstack_quattor_glance default value until we can use the schema defaults from value}
prefix "/software/components/openstack/image/glance/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 9292;
'suffix' ?= '';
