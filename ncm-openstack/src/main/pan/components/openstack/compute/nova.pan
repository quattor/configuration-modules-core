# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/openstack/compute/nova;

include 'components/openstack/identity';

@documentation {
    The Nova configuration options in "api_database" Section.
}
type openstack_nova_api_database = {
    @{The SQLAlchemy connection string to use to connect to the database.
    Example (mysql): mysql+pymysql://nova:<NOVA_DBPASS>@<nova_fqdn>/nova_api
    }
    'connection' : string
};

@documentation {
    The Nova configuration options in the "vnc" Section.
}
type openstack_nova_vnc = {
    @{The IP address or hostname on which an instance should listen to for
    incoming VNC connection requests on this node}
    'vncserver_listen' ? type_ip
    @{Private, internal IP address or hostname of VNC console proxy.
    The VNC proxy is an OpenStack component that enables compute service
    users to access their instances through VNC clients.
    This option sets the private address to which proxy clients, such as
    "nova-xvpvncproxy", should connect to.}
    'vncserver_proxyclient_address' ? type_ip
    @{Enable VNC related features.
    Guests will get created with graphical devices to support this. Clients
    (for example Horizon) can then establish a VNC connection to the guest}
    'enabled' ? boolean
    @{Public address of noVNC VNC console proxy.
    The VNC proxy is an OpenStack component that enables compute service
    users to access their instances through VNC clients. noVNC provides
    VNC support through a websocket-based client.

    This option sets the public base URL to which client systems will
    connect. noVNC clients can use this address to connect to the noVNC
    instance and, by extension, the VNC sessions}
    'novncproxy_base_url' ? type_absoluteURI
};


@documentation {
    The Nova configuration options in the "glance" Section.
}
type openstack_nova_glance = {
    @{List of glance api servers endpoints available to nova.
    https is used for ssl-based glance api servers.

    Possible values:
        * A list of any fully qualified url of the form
        "scheme://hostname:port[/path]"
        (i.e. "http://10.0.1.0:9292" or "https://my.glance.server/image")}
    'api_servers' : type_absoluteURI[]
};

@documentation {
    The Nova configuration options in "placement" Section.
}
type openstack_nova_placement = {
    include openstack_domains_common
    include openstack_region_common
} = dict();

@documentation {
    The Nova hypervisor configuration options in "libvirt" Section.
}
type openstack_nova_libvirt = {
    @{Describes the virtualization type (or so called domain type) libvirt should
    use.

    The choice of this type must match the underlying virtualization strategy
    you have chosen for the host}
    'virt_type' : string = 'kvm' with match (SELF, '^(kvm|lxc|qemu|uml|xen|parallels)$')
    @{The RADOS pool in which rbd volumes are stored}
    'images_rbd_pool' ? string
    @{VM Images format. If default is specified, then use_cow_images flag is used
    instead of this one. Related options: * virt.use_cow_images * images_volume_group}
    'images_type' ? string with match (SELF, '^(raw|flat|qcow2|lvm|rbd|ploop|default)$')
    @{The libvirt UUID of the secret for the rbd_user volumes}
    'rbd_secret_uuid' ? type_uuid
    @{The RADOS client name for accessing rbd(RADOS Block Devices) volumes.
    Libvirt will refer to this user when connecting and authenticating with the Ceph RBD server}
    'rbd_user' ? string
};

@documentation {
    The Nova hypervisor configuration options in "neutron" Section.
}
type openstack_nova_neutron = {
    include openstack_domains_common
    @{Any valid URL that points to the Neutron API service is appropriate here.
    This typically matches the URL returned for the 'network' service type
    from the Keystone service catalog}
    'url' : type_absoluteURI
    @{Region name for connecting to Neutron in admin context.
    This option is used in multi-region setups. If there are two Neutron
    servers running in two regions in two different machines, then two
    services need to be created in Keystone with two different regions and
    associate corresponding endpoints to those services. When requests are made
    to Keystone, the Keystone service uses the region_name to determine the
    region the request is coming from}
    'region_name' : string = 'RegionOne'
    @{This option holds the shared secret string used to validate proxy requests to
    Neutron metadata requests. In order to be used, the
    "X-Metadata-Provider-Signature" header must be supplied in the request}
    'metadata_proxy_shared_secret' ? string
    @{When set to True, this option indicates that Neutron will be used to proxy
    metadata requests and resolve instance ids. Otherwise, the instance ID must be
    passed to the metadata request in the 'X-Instance-ID' header}
    'service_metadata_proxy' ? boolean
};

@documentation {
    The Nova configuration options in the "scheduler" Section.
}
type openstack_nova_scheduler = {
    @{This value controls how often (in seconds) the scheduler should attempt
    to discover new hosts that have been added to cells. If negative (the
    default), no automatic discovery will occur.
    Deployments where compute nodes come and go frequently may want this
    enabled, where others may prefer to manually discover hosts when one
    is added to avoid any overhead from constantly checking. If enabled,
    every time this runs, we will select any unmapped hosts out of each
    cell database on every run.}
    'discover_hosts_in_cells_interval' ? long(-1..)
};

@documentation {
    list of Nova common configuration sections
}
type openstack_nova_common = {
    'DEFAULT' : openstack_DEFAULTS
    'keystone_authtoken' : openstack_keystone_authtoken
    'vnc' : openstack_nova_vnc
    'glance' : openstack_nova_glance
    'oslo_concurrency' : openstack_oslo_concurrency
    @{placement service is mandatory since Ocata release}
    'placement' : openstack_nova_placement
    'cinder' ? openstack_region_common
    'neutron' ? openstack_nova_neutron
};

@documentation {
    list of Nova configuration sections
}
type openstack_nova_config =  {
    include openstack_nova_common
    'database' ? openstack_database
    'api_database' ? openstack_nova_api_database
    'libvirt' ? openstack_nova_libvirt
    'scheduler' ? openstack_nova_scheduler
};
