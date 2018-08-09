unique template components/openstack/identity/gather/compute/nova;

@{openstack_quattor_nova default value until we can use the schema defaults from value}
prefix "/software/components/openstack/compute/nova/quattor";
"service/internal" = dict(
    'port', 8774,
    'suffix', '%(tenant_id)s',
    );

prefix "services";
"placement/type" = "placement";
"placement/internal" = dict(
    'port', 8778,
    );
