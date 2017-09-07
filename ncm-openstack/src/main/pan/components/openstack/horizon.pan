# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/horizon;

@documentation {
    The Horizon configuration options in "caches" Section.
}
type openstack_horizon_caches = {
     @{We recommend you use memcached for development; otherwise after every reload
     of the django development server, you will have to login again}
    'backend' : string = 'django.core.cache.backends.memcached.MemcachedCache'
    @{location format <fqdn>:<port>}
    'location' : string
} = dict();

@documentation {
    The Horizon api versions section.
    Overrides for OpenStack API versions. Use this setting to force the
    OpenStack dashboard to use a specific API version for a given service API.
    Versions specified here should be integers or floats, not strings.
    NOTE: The version should be formatted as it appears in the URL for the
    service API. For example, The identity service APIs have inconsistent
    use of the decimal point, so valid options would be 2.0 or 3.
    Minimum compute version to get the instance locked status is 2.9.
}
type openstack_horizon_api_versions = {
    'identity' : long(1..) = 3
    'image' : long(1..) = 2
    'volume' : long(1..) = 2
};

@documentation {
    The Horizon "OPENSTACK_NEUTRON_NETWORK" settings can be used to enable optional
    services provided by neutron. Options currently available are load
    balancer service, security groups, quotas, VPN service.
}
type openstack_horizon_neutron_network = {
    'enable_router' : boolean = true
    'enable_quotas' : boolean = true
    'enable_ipv6' : boolean = true
    'enable_distributed_router' : boolean = false
    'enable_ha_router' : boolean = false
    'enable_lb' : boolean = true
    'enable_firewall' : boolean = true
    'enable_vpn' : boolean = true
    'enable_fip_topology_check' : boolean = true
};

@documentation {
    list of Horizon service configuration sections
}
type openstack_horizon_config = {
    @{host where is running OpenStack Keystone service}
    'openstack_host' ? type_fqdn
    @{If horizon is running in production (DEBUG is False), set this
    with the list of host/domain names that the application can serve.
    For more information see:
    https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts}
    'allowed_hosts' ? string[] = list('*')
    @{Horizon uses Djangos sessions framework for handling session data.
    There are numerous session backends available, which are selected 
    through the "SESSION_ENGINE" setting}
    'session_engine' ? string = 'django.contrib.sessions.backends.cache'
    @{External caching using an application such as memcached offers persistence
    and shared storage, and can be very useful for small-scale deployment 
    and/or development}
    'caches' ? openstack_horizon_caches{}
    'openstack_keystone_url' ? type_absoluteURI
    @{Set this to True if running on a multi-domain model. When this is enabled, it
    will require the user to enter the Domain name in addition to the username
    for login}
    'openstack_keystone_multidomain_support' ? boolean = true
    'openstack_api_versions' ? openstack_horizon_api_versions
    @{Overrides the default domain used when running on single-domain model
    with Keystone V3. All entities will be created in the default domain.
    NOTE: This value must be the name of the default domain, NOT the ID.
    Also, you will most likely have a value in the keystone policy file like this
    "cloud_admin": "rule:admin_required and domain_id:<your domain id>"
    This value must be the name of the domain whose ID is specified there}
    'openstack_keystone_default_domain' ? string = 'Default'
    @{Configure the default role for users that you create via the dashboard}
    'openstack_keystone_default_role' ? string = 'user'
    'openstack_neutron_network' ? openstack_horizon_neutron_network
    @{The timezone of the server. This should correspond with the timezone
    of your entire OpenStack installation, and hopefully be in UTC.
    Example: "Europe/Brussels"}
    'time_zone' ? string
};
