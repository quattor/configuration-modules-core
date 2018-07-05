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
};



@documentation{
    list of Cinder configuration sections
}
type openstack_cinder_config = {
    'DEFAULT' : openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'oslo_concurrency' : openstack_oslo_concurrency
    'lvm' ? openstack_cinder_lvm
    'ceph' ? openstack_cinder_ceph
};

