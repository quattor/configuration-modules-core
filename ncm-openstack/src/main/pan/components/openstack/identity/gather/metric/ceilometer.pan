unique template components/openstack/identity/gather/metric/ceilometer;

@{openstack_quattor_ceilometer default value until we can use the schema defaults from value}
prefix "/software/components/openstack/metric/ceilometer/quattor";
'service/name' = 'gnocchi';
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8041;
'suffix' ?= '';
