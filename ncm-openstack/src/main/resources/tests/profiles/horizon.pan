object template horizon;

include 'components/openstack/schema';

bind "/metaconfig/contents" = openstack_horizon_config;

"/metaconfig/module" = "horizon";

prefix "/metaconfig/contents";

"allowed_hosts" = list('*');
"openstack_keystone_url" = 'http://controller.mysite.com:5000/v3';
"caches/default" = dict(
    "LOCATION", 'controller.mysite.com:11211',
);
"openstack_keystone_multidomain_support" = true;
"time_zone" = "Europe/Brussels";
"secret_key" = "d5ae8703f268f0effff111";
