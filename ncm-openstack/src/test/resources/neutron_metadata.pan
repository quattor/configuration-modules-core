template neutron_metadata;

include 'components/openstack/config';

prefix "/software/components/openstack/neutron_metadata";

"DEFAULT" = dict(
    "nova_metadata_ip", "controller.mysite.com",
    "metadata_proxy_shared_secret", "metadata_good_password",
);
