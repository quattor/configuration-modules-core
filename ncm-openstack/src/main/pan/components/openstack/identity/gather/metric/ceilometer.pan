unique template components/openstack/identity/gather/metric/ceilometer;

@{openstack_quattor_ceilometer default value until we can use the schema defaults from value}
prefix "/software/components/openstack/metric/ceilometer/quattor";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8041;
'suffix' ?= '';

prefix "services/gnocchi";
"type" = "metric";
"internal/port" ?= 8041;
"internal/suffix" ?= '';
