object template neutron_metadata;

include 'components/openstack/schema';

bind "/metaconfig/contents/neutron_metadata" = openstack_neutron_metadata_config;

"/metaconfig/module" = "openstack_common";

prefix "/metaconfig/contents/neutron_metadata";

"DEFAULT" = dict(
    "nova_metadata_ip", "controller.mysite.com",
    "metadata_proxy_shared_secret", "metadata_good_password",
);
