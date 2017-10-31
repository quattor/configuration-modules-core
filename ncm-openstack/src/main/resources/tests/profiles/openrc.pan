object template openrc;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_openrc_config;

"/metaconfig/module" = "openrc";

variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';

prefix "/metaconfig/contents";
"os_password" = "admingoodpass";
"os_auth_url" = format("http://%s:35357/v3", OPENSTACK_HOST_SERVER);
