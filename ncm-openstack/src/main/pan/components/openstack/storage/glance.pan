# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/storage/glance;

include 'components/openstack/identity';

@documentation {
    The Glance configuration options in the "glance_store" Section.
    From glance.api
}
type openstack_glance_store = {
    @{List of enabled Glance stores.
    Register the storage backends to use for storing disk images
    as a comma separated list. The default stores enabled for
    storing disk images with Glance are "file" and "http"}
    'stores' : openstack_storagebackend[] = list ('file', 'http')
    @{The default scheme to use for storing images.
    Provide a string value representing the default scheme to use for
    storing images. If not set, Glance uses ``file`` as the default
    scheme to store images with the ``file`` store.
    NOTE: The value given for this configuration option must be a valid
    scheme for a store registered with the ``stores`` configuration
    option.}
    'default_store' : choice('file', 'filesystem', 'http',
        'https', 'swift', 'swift+http', 'swift+https', 'swift+config', 'rbd',
        'sheepdog', 'cinder', 'vsphere') = 'file'
    @{Directory to which the filesystem backend store writes images.
    Upon start up, Glance creates the directory if it does not already
    exist and verifies write access to the user under which
    "glance-api" runs. If the write access is not available, a
    BadStoreConfiguration`` exception is raised and the filesystem
    store may not be available for adding new images.

    NOTE: This directory is used only when filesystem store is used as a
    storage backend. Either ``filesystem_store_datadir`` or
    filesystem_store_datadirs`` option must be specified in
    "glance-api.conf". If both options are specified, a
    BadStoreConfiguration will be raised and the filesystem store
    may not be available for adding new images}
    'filesystem_store_datadir' : absolute_file_path = '/var/lib/glance/images'
    @{This option is specific to the RBD storage backend.
    Default: rbd
    Sets the RADOS pool in which images are stored}
    'rbd_store_pool' ? string = 'images'
    @{This option is specific to the RBD storage backend.
    Default: 4
    Images will be chunked into objects of this size (in megabytes).
    For best performance, this should be a power of two}
    'rbd_store_chunk_size' ? long(1..)
    @{This option is specific to the RBD storage backend.
    Default: 0
    Prevents glance-api hangups during the connection to RBD.
    Sets the time to wait (in seconds) for glance-api before closing the connection.
    Setting rados_connect_timeout<=0 means no timeout}
    'rados_connect_timeout' ? long
    @{This option is specific to the RBD storage backend.
    Default: /etc/ceph/ceph.conf, ~/.ceph/config, and ./ceph.conf
    Sets the Ceph configuration file to use}
    'rbd_store_ceph_conf' ? absolute_file_path = '/etc/ceph/ceph.conf'
    @{This option is specific to the RBD storage backend.
    Default: admin
    Sets the RADOS user to authenticate as.
    This is only needed when RADOS authentication is enabled}
    'rbd_store_user' ? string = 'images'
};

@documentation {
    list of Glance configuration sections
}
type openstack_glance_service_config = {
    'DEFAULT' ? openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'paste_deploy' : openstack_keystone_paste_deploy
    'glance_store' ? openstack_glance_store
};

@documentation {
    list of Glance service configuration sections
}
type openstack_glance_config = {
    'service' ? openstack_glance_service_config
    'registry' ? openstack_glance_service_config
};
