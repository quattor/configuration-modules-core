template os_resources;


include 'common_resources';


# Identity/ keystone section
prefix "/software/components/openstack/identity";

prefix "keystone";
"database" = dict(
    "connection", "mysql+pymysql://keystone:keystone_db_pass@controller.mysite.com/keystone",
);

prefix "region";
"regionOne/description" = "abc";
"regionTwo/description" = "def";
"regionThree/description" = "xyz";
"regionThree/parent_region_id" = "regionTwo";

prefix "domain";
"vo1/description" = "vo1";
"vo2/description" = "vo2";

prefix "project/vo1";
"description" = "main vo1 project";
"domain_id" = "vo1";
prefix "project/realproject";
"description" = "some real project";
"parent_id" = "vo1";
# default description
prefix "project";
"opq" = dict();

prefix "project/vo2";
"description" = "main vo2 project";
"domain_id" = "vo2";

prefix "user/user1";
"description" = "first user";
"password" = "abc";

prefix "group/grp1";
"description" = "first group";
"domain_id" = "vo2";

prefix "service/glance";
"description" = "OS image";
"type" = "image";

# Glance/service section

prefix "/software/components/openstack/storage/glance/service";
"database" = dict(
    "connection", format("mysql+pymysql://glance:glance_db_pass@%s/glance", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "glance",
    "password", "glance_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"glance_store" = dict(
    "default_store", "file",
);


# Glance/registry section

prefix "/software/components/openstack/storage/glance/registry";
"database" = dict(
    "connection", format("mysql+pymysql://glance:glance_db_pass@%s/glance", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "glance",
    "password", "glance_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);


# Horizon section

prefix "/software/components/openstack/dashboard/horizon";
"allowed_hosts" = list('*');
"openstack_keystone_url" = 'http://controller.mysite.com:5000/v3';
"caches/default" = dict(
    "LOCATION", 'controller.mysite.com:11211',
);
"openstack_keystone_multidomain_support" = true;
"time_zone" = "Europe/Brussels";
"secret_key" = "d5ae8703f268f0effff111";


# Neutron section

prefix "/software/components/openstack/network/neutron/service";
"database" = dict(
    "connection", format("mysql+pymysql://neutron:neutron_db_pass@%s/neutron", OPENSTACK_HOST_SERVER),
);
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "core_plugin", "ml2",
    "service_plugins", list('router'),
    "allow_overlapping_ips", true,
    "notify_nova_on_port_status_changes", true,
    "notify_nova_on_port_data_changes", true,
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
);
"nova" = dict(
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
);


# Neutron/DHCP section

prefix "/software/components/openstack/network/neutron/dhcp";
"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
    "dhcp_driver", "neutron.agent.linux.dhcp.Dnsmasq",
    "enable_isolated_metadata", true,
);


# Neutron/L3 section

prefix "/software/components/openstack/network/neutron/l3";
"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
);


# Neutron/Metadata section

prefix "/software/components/openstack/network/neutron/metadata";
"DEFAULT" = dict(
    "nova_metadata_ip", "controller.mysite.com",
    "metadata_proxy_shared_secret", "metadata_good_password",
);


# Neutron/ML2 section

prefix "/software/components/openstack/network/neutron/ml2";
"ml2_type_vxlan" = dict(
    'vni_ranges', '1:1000',
);
"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);


# Nova section

prefix "/software/components/openstack/compute/nova";
"database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova", OPENSTACK_HOST_SERVER),
);
"api_database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova_api", OPENSTACK_HOST_SERVER),
);
"vnc" = dict(
    "vncserver_listen", MY_IP,
    "vncserver_proxyclient_address", MY_IP,
);
"neutron" = dict(
    "url", format('http://%s:9696', NEUTRON_HOST_SERVER),
    "auth_url", format('http://%s:35357', NEUTRON_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "service_metadata_proxy", true,
    "metadata_proxy_shared_secret", "metadata_good_password",
);

# OpenRC section

prefix "/software/components/openstack/openrc";
"os_username" = "admin";
"os_password" = "admingoodpass";
"os_region_name" = "RegionOne";
"os_auth_url" = format("http://%s:35357/v3", OPENSTACK_HOST_SERVER);

# RabbitMQ section
prefix "/software/components/openstack/messaging/rabbitmq";
"password" = "rabbit_pass";
