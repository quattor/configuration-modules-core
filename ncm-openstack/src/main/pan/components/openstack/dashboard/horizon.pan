# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/dashboard/horizon;

@documentation {
    The Horizon configuration options in "caches" Section.
}
type openstack_horizon_caches = {
     @{We recommend you use memcached for development; otherwise after every reload
     of the django development server, you will have to login again}
    'BACKEND' : string = 'django.core.cache.backends.memcached.MemcachedCache'
    @{location format <fqdn>:<port>}
    'LOCATION' : type_hostport[] = list('127.0.0.1:11211')
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
} = dict();

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
} = dict();

@documentation {
    The OPENSTACK_KEYSTONE_BACKEND settings can be used to identify the
    capabilities of the auth backend for Keystone.
    If Keystone has been configured to use LDAP as the auth backend then set
    can_edit_user to False and name to 'ldap'.
    TODO(tres): Remove these once Keystone has an API to identify auth backend.
}
type openstack_horizon_keystone_backend = {
    'name' : string = 'native' with match (SELF, '^(native|ldap)$')
    'can_edit_user' : boolean = true
    'can_edit_group' : boolean = true
    'can_edit_project' : boolean = true
    'can_edit_domain' : boolean = true
    'can_edit_role' : boolean = true
} = dict();

@documentation {
    The Xen Hypervisor has the ability to set the mount point for volumes
    attached to instances (other Hypervisors currently do not). Setting
    can_set_mount_point to True will add the option to set the mount point
    from the UI.
}
type openstack_horizon_hypervisor_features = {
    'can_set_mount_point' : boolean = false
    'can_set_password' : boolean = false
    'requires_keypair' : boolean = false
    'enable_quotas' : boolean = true
} = dict();

@documentation {
    The OPENSTACK_CINDER_FEATURES settings can be used to enable optional
    services provided by cinder that is not exposed by its extension API.
}
type openstack_horizon_cinder_features = {
    'enable_backup' : boolean = false
} = dict();

@documentation {
    The OPENSTACK_HEAT_STACK settings can be used to disable password
    field required while launching the stack.
}
type openstack_horizon_heat_stack = {
    'enable_user_pass' : boolean = true
} = dict();

@documentation {
    The IMAGE_CUSTOM_PROPERTY_TITLES settings is used to customize the titles for
    image custom property attributes that appear on image detail pages.
}
type openstack_horizon_image_custom_titles = {
    'architecture' : string = 'Architecture'
    'kernel_id' : string = 'Kernel ID'
    'ramdisk_id' : string = 'Ramdisk ID'
    'image_state' : string = 'Euca2ools state'
    'project_id' : string = 'Project ID'
    'image_type' : string = 'Image Type'
} = dict();

@documentation{
    Dashboard handlers logging levels.
}
type openstack_horizon_logging_handlers = {
    'level' : string = 'INFO' with match (SELF, '^(INFO|DEBUG)$')
    'class' : string = 'logging.StreamHandler' with match (SELF, '^(logging.NullHandler|logging.StreamHandler)$')
    'formatter' ? string = 'operation'
} = dict();

@documentation{
    Dashboard django loggers debug levels
}
type openstack_horizon_logging_loggers = {
    'handlers' : string = 'console' with match (SELF, '^(console|null|operation)$')
    'level' ? string = 'DEBUG' with match (SELF, '^(INFO|DEBUG)$')
    'propagate' : boolean = false
} = dict();

@documentation{
    Dashboard django logger formatters
}
type openstack_horizon_logging_formatters = {
    @{The format of "%(message)s" is defined by
    OPERATION_LOG_OPTIONS['format']}
    'format' : string = '%(asctime)s %(message)s'
} = dict();

@documentation {
    Horizon django logging options.
    Logging from django.db.backends is VERY verbose, send to null
    by default.
}
type openstack_horizon_logging = {
    'version' : long(1..) = 1
    @{When set to True this will disable all logging except
    for loggers specified in this configuration dictionary. Note that
    if nothing is specified here and disable_existing_loggers is True,
    django.db.backends will still log unless it is disabled explicitly}
    'disable_existing_loggers' : boolean = false
    'handlers' : openstack_horizon_logging_handlers{} = dict(
        "null", dict("level", "DEBUG", "class", "logging.NullHandler"),
        "console", dict(),
        "operation", dict("formatter", "operation"),
    )
    'loggers' : openstack_horizon_logging_loggers{} = dict(
        "django.db.backends", dict("handlers", "null"),
        "requests", dict("handlers", "null"),
        "horizon", dict("level", "DEBUG"),
        "horizon.operation_log", dict("handlers", "operation", "level", "INFO"),
        "openstack_dashboard", dict("level", "DEBUG"),
        "novaclient", dict("level", "DEBUG"),
        "cinderclient", dict("level", "DEBUG"),
        "keystoneclient", dict("level", "DEBUG"),
        "glanceclient", dict("level", "DEBUG"),
        "neutronclient", dict("level", "DEBUG"),
        "heatclient", dict("level", "DEBUG"),
        "swiftclient", dict("level", "DEBUG"),
        "openstack_auth", dict("level", "DEBUG"),
        "nose.plugins.manager", dict("level", "DEBUG"),
        "django", dict("level", "DEBUG"),
        "iso8601", dict("handlers", "null"),
        "scss", dict("handlers", "null"),
    )
    'formatters' : openstack_horizon_logging_formatters{} = dict(
        "operation", dict(),
    )
} = dict();

@documentation {
    Dictionary used to restrict user private subnet cidr range.
    An empty list means that user input will not be restricted
    for a corresponding IP version. By default, there is
    no restriction for IPv4 or IPv6. To restrict
    user private subnet cidr range set ALLOWED_PRIVATE_SUBNET_CIDR
    to something like:
        'ipv4': ['10.0.0.0/8', '192.168.0.0/16'],
        'ipv6': ['fc00::/7'],
}
type openstack_horizon_allowed_subnet = {
    'ipv4' ? type_ipv4[]
    'ipv6' ? type_ipv6[]
} = dict();

@documentation {
    "direction" should not be specified for all_tcp, udp or icmp.
}
type openstack_horizon_security_group = {
    'name' : string
    'ip_protocol' : string = 'tcp' with match (SELF, '^(tcp|udp|icmp)$')
    'from_port' : long(-1..65535)
    'to_port' : long(-1..65535)
} = dict();

@documentation {
    list of Horizon service configuration sections
}
type openstack_horizon_config = {
    @{Set Horizon debug mode}
    'debug' : boolean = false
    @{WEBROOT is the location relative to Webserver root
    should end with a slash}
    'webroot' : string = '/dashboard/' with match (SELF, '^/.+/$')
    @{If horizon is running in production (DEBUG is False), set this
    with the list of host/domain names that the application can serve.
    For more information see:
    https://docs.djangoproject.com/en/dev/ref/settings/#allowed-hosts}
    'allowed_hosts' ? string[] = list('*')
    @{Horizon uses Djangos sessions framework for handling session data.
    There are numerous session backends available, which are selected
    through the "SESSION_ENGINE" setting}
    'session_engine' : string = 'django.contrib.sessions.backends.cache'
    @{Send email to the console by default}
    'email_backend' : string = 'django.core.mail.backends.console.EmailBackend'
    @{External caching using an application such as memcached offers persistence
    and shared storage, and can be very useful for small-scale deployment
    and/or development}
    'caches' ? openstack_horizon_caches{}
    'openstack_keystone_url' : type_absoluteURI
    @{Set this to True if running on a multi-domain model. When this is enabled, it
    will require the user to enter the Domain name in addition to the username
    for login}
    'openstack_keystone_default_role' : string = 'user'
    'openstack_keystone_multidomain_support' : boolean = true
    'openstack_keystone_backend' : openstack_horizon_keystone_backend
    'openstack_api_versions' : openstack_horizon_api_versions
    'openstack_hypervisor_features' : openstack_horizon_hypervisor_features
    'openstack_cinder_features' : openstack_horizon_cinder_features
    'openstack_heat_stack' : openstack_horizon_heat_stack
    'image_custom_property_titles' : openstack_horizon_image_custom_titles
    @{The IMAGE_RESERVED_CUSTOM_PROPERTIES setting is used to specify which image
    custom properties should not be displayed in the Image Custom Properties
    table}
    'image_reserved_custom_properties' ? string[]
    @{The number of objects (Swift containers/objects or images) to display
    on a single page before providing a paging element (a "more" link)
    to paginate results}
    'api_result_limit' : long(1..) = 1000
    'api_result_page_size' : long(1..) = 20
    @{The size of chunk in bytes for downloading objects from Swift}
    'swift_file_transfer_chunk_size' : long(1..) = 524288
    @{The default number of lines displayed for instance console log}
    'instance_log_length' : long(1..) = 35
    'local_path' : absolute_file_path = '/tmp'
    @{You can either set it to a specific value or you can let horizon generate a
    default secret key that is unique on this machine, e.i. regardless of the
    amount of Python WSGI workers (if used behind Apache+mod_wsgi): However,
    there may be situations where you would want to set this explicitly, e.g.
    when multiple dashboard instances are distributed on different machines
    (usually behind a load-balancer). Either you have to make sure that a session
    gets all requests routed to the same dashboard instance or you set the same
    SECRET_KEY for all of them}
    'secret_key' : string
    @{Overrides the default domain used when running on single-domain model
    with Keystone V3. All entities will be created in the default domain.
    NOTE: This value must be the name of the default domain, NOT the ID.
    Also, you will most likely have a value in the keystone policy file like this
    "cloud_admin": "rule:admin_required and domain_id:<your domain id>"
    This value must be the name of the domain whose ID is specified there}
    'openstack_keystone_default_domain' : string = 'Default'
    @{Configure the default role for users that you create via the dashboard}
    'openstack_keystone_default_role' : string = 'user'
    'openstack_neutron_network' : openstack_horizon_neutron_network
    @{The timezone of the server. This should correspond with the timezone
    of your entire OpenStack installation, and hopefully be in UTC.
    Example: "Europe/Brussels"}
    'time_zone' ? string
    @{Path to directory containing policy.json files}
    'policy_files_path' : absolute_file_path = '/etc/openstack-dashboard'
    'logging' : openstack_horizon_logging
    @{AngularJS requires some settings to be made available to
    the client side. Some settings are required by in-tree / built-in horizon
    features. These settings must be added to REST_API_REQUIRED_SETTINGS in the
    form of ['SETTING_1','SETTING_2'], etc.
    You may remove settings from this list for security purposes, but do so at
    the risk of breaking a built-in horizon feature. These settings are required
    for horizon to function properly. Only remove them if you know what you
    are doing. These settings may in the future be moved to be defined within
    the enabled panel configuration.
    You should not add settings to this list for out of tree extensions}
    'rest_api_required_settings' : string[] = list(
        'OPENSTACK_HYPERVISOR_FEATURES', 'LAUNCH_INSTANCE_DEFAULTS',
        'OPENSTACK_IMAGE_FORMATS', 'OPENSTACK_KEYSTONE_DEFAULT_DOMAIN',
        )
    'allowed_private_subnet_cidr' ? openstack_horizon_allowed_subnet
    'security_group_files' : openstack_horizon_security_group{} = dict(
        'all_tcp', dict('name', 'ALL TCP', 'from_port', 1, 'to_port', 65535),
        'all_udp', dict('name', 'ALL UDP', 'from_port', 1, 'to_port', 65535, 'ip_protocol', 'udp'),
        'all_icmp', dict('name', 'ALL ICMP', 'from_port', -1, 'to_port', -1, 'ip_protocol', 'icmp'),
        'ssh', dict('name', 'SSH', 'from_port', 22, 'to_port', 22),
        'smtp', dict('name', 'SMTP', 'from_port', 25, 'to_port', 25),
        'dns', dict('name', 'DNS', 'from_port', 53, 'to_port', 53),
        'http', dict('name', 'HTTP', 'from_port', 80, 'to_port', 80),
        'pop3', dict('name', 'POP3', 'from_port', 110, 'to_port', 110),
        'imap', dict('name', 'IMAP', 'from_port', 143, 'to_port', 143),
        'ldap', dict('name', 'LDAP', 'from_port', 389, 'to_port', 389),
        'https', dict('name', 'HTTPS', 'from_port', 443, 'to_port', 443),
        'smtps', dict('name', 'SMTPS', 'from_port', 465, 'to_port', 465),
        'imaps', dict('name', 'IMAPS', 'from_port', 993, 'to_port', 993),
        'pop3s', dict('name', 'POP3S', 'from_port', 995, 'to_port', 995),
        'ms_sql', dict('name', 'MS SQL', 'from_port', 1433, 'to_port', 1433),
        'mysql', dict('name', 'MYSQL', 'from_port', 3306, 'to_port', 3306),
        'rdp', dict('name', 'RDP', 'from_port', 3389, 'to_port', 3389),
        )
};
