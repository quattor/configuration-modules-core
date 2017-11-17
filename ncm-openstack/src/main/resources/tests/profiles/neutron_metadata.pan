object template neutron_metadata;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_neutron_metadata_config;

"/metaconfig/module" = "common";

prefix "/metaconfig/contents";

"DEFAULT" = dict(
    "nova_metadata_ip", "controller.mysite.com",
    "metadata_proxy_shared_secret", "metadata_good_password",
);
