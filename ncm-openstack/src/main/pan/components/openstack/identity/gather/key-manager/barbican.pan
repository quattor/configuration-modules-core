unique template components/openstack/identity/gather/key-manager/barbican;

@{openstack_quattor_barbican default value until we can use the schema defaults from value}
prefix "/software/components/openstack/key-manager/barbican/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 9311;
'suffix' ?= '';
