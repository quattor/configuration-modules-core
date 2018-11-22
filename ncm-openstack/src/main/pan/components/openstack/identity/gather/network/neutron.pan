unique template components/openstack/identity/gather/network/neutron;

@{openstack_quattor_neutron default value until we can use the schema defaults from value}
prefix "/software/components/openstack/network/neutron/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 9696;
'suffix' ?= '';
