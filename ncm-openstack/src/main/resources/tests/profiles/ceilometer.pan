object template ceilometer;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_ceilometer_service_config;

"/metaconfig/module" = "common";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';

prefix "/metaconfig/contents";

"DEFAULT" = dict(
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"service_credentials" = dict(
    "auth_url", format('http://%s:5000/v3', OPENSTACK_HOST_SERVER),
    "username", "ceilometer",
    "password", "ceilometer_good_password",
    "interface", "internalURL",
);
