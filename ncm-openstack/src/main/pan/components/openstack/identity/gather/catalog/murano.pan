unique template components/openstack/identity/gather/catalog/murano;

@{openstack_quattor_murano default value until we can use the schema defaults from value}
prefix "/software/components/openstack/catalog/murano/quattor";
"service/type" = "application-catalog";
prefix "service/internal";
'proto' ?= 'https';
'host' ?= OBJECT;
'port' ?= 8082;
'suffix' ?= '';

