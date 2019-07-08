# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/volume/cinder;

include 'components/openstack/identity';

@documentation{
    The Cinder configuration options in the "lvm" Section.
}
type openstack_cinder_lvm = {
    @{Driver to use for volume creation}
    'volume_driver' : string = 'cinder.volume.drivers.lvm.LVMVolumeDriver'
    @{Name for the VG that will contain exported volumes}
    'volume_group' : string = 'cinder-volumes'
    @{Determines the iSCSI protocol for new iSCSI volumes, created with tgtadm or
    lioadm target helpers. In order to enable RDMA, this parameter should be set
    with the value "iser"}
    'iscsi_protocol' : choice('iscsi', 'iser') = 'iscsi'
    @{iSCSI target user-land tool to use. tgtadm is default, use lioadm for LIO
    iSCSI support, scstadmin for SCST target support, ietadm for iSCSI Enterprise
    Target, iscsictl for Chelsio iSCSI Target or fake for testing}
    'iscsi_helper' : choice('tgtadm', 'lioadm', 'scstadmin', 'iscsictl', 'ietadm', 'fake') = 'lioadm'
};

@documentation{
    The Cinder configuration options in the "ceph" Section.
}
type openstack_cinder_ceph = {
    @{The backend name for a given driver implementation}
    'volume_backend_name' : string = 'ceph'
    @{The RADOS pool where rbd volumes are stored}
    'rbd_pool' : string = 'volumes'
    @{The RADOS client name for accessing rbd volumes - only set when using cephx
    authentication}
    'rbd_user' : string = 'volumes'
    @{The libvirt uuid of the secret for the rbd_user volumes}
    'rbd_secret_uuid' : type_uuid
    @{Driver to use for volume creation}
    'volume_driver' : string = 'cinder.volume.drivers.rbd.RBDDriver'
    @{Path to the ceph configuration file}
    'rbd_ceph_conf' : absolute_file_path = '/etc/ceph/ceph.conf'
    @{Flatten volumes created from snapshots to remove dependency from volume to
    snapshot}
    "rbd_flatten_volume_from_snapshot" ? boolean
    @{Maximum number of nested volume clones that are taken before a flatten
    occurs. Set to 0 to disable cloning}
    "rbd_max_clone_depth" ? long(0..)
    @{Volumes will be chunked into objects of this size (in megabytes)}
    "rbd_store_chunk_size" ? long(1..)
    @{Timeout value (in seconds) used when connecting to ceph cluster. If value <
    0, no timeout is set and default librados value is used}
    "rados_connect_timeout" ? long(-1..)
    @{Set to True if the pool is used exclusively by Cinder. On exclusive use
    driver wont query images provisioned size as they will match the value
    calculated by the Cinder core code for allocated_capacity_gb. This reduces
    the load on the Ceph cluster as well as on the volume service}
    "rbd_exclusive_cinder_pool" ? boolean
    @{Enable the image volume cache for this backend}
    "image_volume_cache_enabled" ? boolean
};

type openstack_quattor_cinder = openstack_quattor;

@documentation{
    list of Cinder configuration sections
}
type openstack_cinder_config = {
    'DEFAULT' : openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'oslo_concurrency' : openstack_oslo_concurrency
    'oslo_messaging_notifications' ? openstack_oslo_messaging_notifications
    'lvm' ? openstack_cinder_lvm
    'ceph' ? openstack_cinder_ceph
    # default empty dict for pure hypervisor
    'quattor' : openstack_quattor_cinder = dict()
};

