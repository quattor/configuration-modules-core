# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/manila;

include 'components/openstack/identity';


type openstack_manila_share_driver = string with match(SELF,
    '^(manila.share.drivers.lvm.LVMShareDriver|manila.share.drivers.cephfs.driver.CephFSDriver|manila.share.drivers.generic.GenericShareDriver)$');

@documentation {
    Common Manila storage backends options
}
type openstack_manila_common = {
    @{The backend name for a given driver implementation}
    'share_backend_name' : string
    @{Driver to use for share creation}
    'share_driver' : openstack_manila_share_driver
    @{There are two possible approaches for share drivers in Manila. First
    is when share driver is able to handle share-servers and second when
    not. Drivers can support either both or only one of these
    approaches. So, set this opt to True if share driver is able to
    handle share servers and it is desired mode else set False. It is
    set to None by default to make this choice intentional}
    'driver_handles_share_servers' : boolean = false

};

@documentation {
    The Manila configuration options in the "lvm" Section.
}
type openstack_manila_lvm = {
    include openstack_manila_common
     @{Name for the VG that will contain exported shares}
    'lvm_share_volume_group' : string = 'manila-volumes'
    @{List of IPs to export shares}
    'lvm_share_export_ip' ? type_ip
};

@documentation {
    The Manila configuration options in the "ceph" Section.
}
type openstack_manila_ceph = {
    include openstack_manila_common
    @{Fully qualified path to the ceph.conf file}
    'cephfs_conf_path' : absolute_file_path = '/etc/ceph/ceph.conf'
    @{The type of protocol helper to use. Default is CEPHFS}
    'cephfs_protocol_helper_type' : string = 'CEPHFS' with match (SELF, '^(CEPHFS|NFS)$')
    @{The name of the ceph auth identity to use}
    'cephfs_auth_id' : string = 'manila'
    @{The name of the cluster in use, if it is not the default ('ceph')}
    'cephfs_cluster_name' : string = 'ceph'
    @{Whether to enable snapshots in this driver.
    Note that the snapshot support for the CephFS driver is experimental
    and is known to have several caveats for use. Only enable this and
    the equivalent manila.conf option if you understand these risks.
    See (http://docs.ceph.com/docs/master/cephfs/experimental-features/)
    for more details}
    'cephfs_enable_snapshots' : boolean = false
    @{Whether the NFS-Ganesha server is remote to the driver}
    'cephfs_ganesha_server_is_remote' ? boolean = false
    @{The IP address of the NFS-Ganesha server}
    'cephfs_ganesha_server_ip' ? type_ip
    @{sets the username (NFSGADMIN) that the File Share Service should use
    to manage the NFS-Ganesha service}
    'cephfs_ganesha_server_username' ? string
    @{sets the corresponding password (NFSGPW) of the username defined
    in cephfs_ganesha_server_username}
    'cephfs_ganesha_server_password' ? string
    @{sets the SSH private key path used by cephfs_ganesha_server_username
    to get access to the NFS-Ganesha service}
    'cephfs_ganesha_path_to_private_key' ? absolute_file_path
    @{Persist Ganesha exports and export counter in Ceph RADOS objects,
    highly available storage}
    'ganesha_rados_store_enable' ? boolean = true
    @{Name of the Ceph RADOS pool to store Ganesha exports and export
    counter}
    'ganesha_rados_store_pool_name' ? string = 'cephfs_data'

};

@documentation {
    The Manila configuration options in the "generic" Section.
}
type openstack_manila_generic = {
    include openstack_manila_common
    @{ID of flavor, that will be used for service instance creation. Only
    used if driver_handles_share_servers=True}
    'service_instance_flavor_id' : long(1..) = 100
    @{Name of image in Glance, that will be used for service instance
    creation. Only used if driver_handles_share_servers=True}
    'service_image_name' : string = 'manila-service-image'
    @{User in service instance that will be used for authentication}
    'service_instance_user' : string = 'manila'
    @{Password for service instance user}
    'service_instance_password' : string
    @{Vif driver. Used only with Neutron and if
    driver_handles_share_servers=True}
    'interface_driver' : string = 'manila.network.linux.interface.BridgeInterfaceDriver'
};

@documentation {
    The manila configuration options in the "neutron" section.
}
type openstack_manila_neutron = {
    include openstack_keystone_authtoken
    @{Any valid URL that points to the Neutron API service is appropriate here.
    This typically matches the URL returned for the 'network' service type
    from the Keystone service catalog}
    'url' : type_absoluteURI
};

@documentation {
    list of Manila configuration sections
}
type openstack_manila_config = {
    'DEFAULT' : openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'oslo_concurrency' : openstack_oslo_concurrency
    'cephfsnative' ? openstack_manila_ceph
    'cephfsnfs' ? openstack_manila_ceph
    'lvm' ? openstack_manila_lvm
    'generic' ? openstack_manila_generic
    'neutron' ? openstack_manila_neutron
    'nova' ? openstack_keystone_authtoken
    'cinder' ? openstack_keystone_authtoken
};
