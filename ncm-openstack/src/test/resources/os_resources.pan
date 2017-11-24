template os_resources;


variable OPENSTACK_HOST_SERVER ?= 'controller.mysite.com';
variable NEUTRON_HOST_SERVER ?= 'neutron.mysite.com';
variable MY_IP ?= '10.0.1.2';


# Hardware section

prefix "/system/network";
"domainname" = "mysite.com";
"hostname" = "controller";


# Keystone section

prefix "/software/components/openstack/identity/keystone";
"database" = dict(
    "connection", "mysql+pymysql://keystone:keystone_db_pass@controller.mysite.com/keystone",
);


# Glance section

prefix "/software/components/openstack/storage/glance";
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
    "location", 'controller.mysite.com:11211',
);
"openstack_keystone_multidomain_support" = true;
"time_zone" = "Europe/Brussels";
"secret_key" = "d5ae8703f268f0effff111";


# Neutron section

prefix "/software/components/openstack/network/neutron/neutron";

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
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"nova" = dict(
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/neutron/tmp",
);


# Neutron/DHCP section

prefix "/software/components/openstack/network/neutron/neutron_dhcp";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
    "dhcp_driver", "neutron.agent.linux.dhcp.Dnsmasq",
    "enable_isolated_metadata", true,
);


# Neutron/L3 section

prefix "/software/components/openstack/network/neutron/neutron_l3";

"DEFAULT" = dict(
    "interface_driver", "linuxbridge",
);


# Neutron/Linuxbridge section

prefix "/software/components/openstack/network/neutron/neutron_linuxbridge";

"linux_bridge" = dict(
    "physical_interface_mappings", list('provider:eth1'),
);
"vxlan" = dict(
    "enable_vxlan", true,
    "local_ip", "10.0.1.4",
    "l2_population", true,
);
"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);


# Neutron/Metadata section

prefix "/software/components/openstack/network/neutron/neutron_metadata";

"DEFAULT" = dict(
    "nova_metadata_ip", "controller.mysite.com",
    "metadata_proxy_shared_secret", "metadata_good_password",
);


# Neutron/ML2 section

prefix "/software/components/openstack/network/neutron/neutron_ml2";

"securitygroup" = dict(
    "enable_security_group", true,
    "firewall_driver", "neutron.agent.linux.iptables_firewall.IptablesFirewallDriver",
);


# Nova section

prefix "/software/components/openstack/compute/nova";
"database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova", OPENSTACK_HOST_SERVER),
);
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "enabled_apis", list('osapi_compute', 'metadata'),
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "my_ip", MY_IP,
    "rootwrap_config", "/etc/nova/rootwrap.conf",
);
"api_database" = dict(
    "connection", format("mysql+pymysql://nova:nova_db_pass@%s/nova_api", OPENSTACK_HOST_SERVER),
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"vnc" = dict(
    "vncserver_listen", MY_IP,
    "vncserver_proxyclient_address", MY_IP,
);
"glance" = dict(
    "api_servers", list(format('http://%s:9292', OPENSTACK_HOST_SERVER)),
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/nova/tmp",
);
"placement" = dict(
    "auth_url", format('http://%s:35357/v3', OPENSTACK_HOST_SERVER),
    "username", "placement",
    "password", "placement_good_password",
);
"neutron" = dict(
    "url", format('http://%s:9696', NEUTRON_HOST_SERVER),
    "auth_url", format('http://%s:35357', NEUTRON_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
    "service_metadata_proxy", true,
    "metadata_proxy_shared_secret", "metadata_good_password",
);


# Nova/Compute section

prefix "/software/components/openstack/hypervisor/nova";
"DEFAULT" = dict(
    "auth_strategy", "keystone",
    "enabled_apis", list('osapi_compute', 'metadata'),
    "transport_url", format("rabbit://openstack:rabbit_pass@%s", OPENSTACK_HOST_SERVER),
    "my_ip", MY_IP,
    "rootwrap_config", "/etc/nova/rootwrap.conf",
);
"keystone_authtoken" = dict(
    "auth_uri", format('http://%s:5000', OPENSTACK_HOST_SERVER),
    "auth_url", format('http://%s:35357', OPENSTACK_HOST_SERVER),
    "username", "nova",
    "password", "nova_good_password",
    "memcached_servers", list('controller.mysite.com:11211'),
);
"vnc" = dict(
    "enabled", true,
    "vncserver_listen", "0.0.0.0",
    "vncserver_proxyclient_address", MY_IP,
    "novncproxy_base_url", format('http://%s:6080/vnc_auto.html', OPENSTACK_HOST_SERVER),
);
"glance" = dict(
    "api_servers", list(format('http://%s:9292', OPENSTACK_HOST_SERVER)),
);
"oslo_concurrency" = dict(
    "lock_path", "/var/lib/nova/tmp",
);
"placement" = dict(
    "auth_url", format('http://%s:35357/v3', OPENSTACK_HOST_SERVER),
    "username", "placement",
    "password", "placement_good_password",
);
"libvirt" = dict(
    "virt_type", "kvm",
);
"neutron" = dict(
    "url", format('http://%s:9696', NEUTRON_HOST_SERVER),
    "auth_url", format('http://%s:35357', NEUTRON_HOST_SERVER),
    "username", "neutron",
    "password", "neutron_good_password",
);


# OpenRC section

prefix "/software/components/openstack/openrc";
"os_username" = "admin";
"os_password" = "admingoodpass";
"os_region_name" = "RegionOne";
"os_auth_url" = format("http://%s:35357/v3", OPENSTACK_HOST_SERVER);
"os_project_domain_id" = "Default";
