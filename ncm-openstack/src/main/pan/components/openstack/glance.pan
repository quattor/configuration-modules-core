# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/openstack/glance;

include 'components/openstack/keystone';

@documentation {
    The Glance configuration options in the "glance_store" Section.
    From glance.api
}
type openstack_glance_store = {
    @{List of enabled Glance stores.
    Register the storage backends to use for storing disk images
    as a comma separated list. The default stores enabled for
    storing disk images with Glance are "file" and "http"}
    'stores' : type_storagebackend[] = list ('file', 'http')
    @{The default scheme to use for storing images.
    Provide a string value representing the default scheme to use for
    storing images. If not set, Glance uses ``file`` as the default
    scheme to store images with the ``file`` store.
    NOTE: The value given for this configuration option must be a valid
    scheme for a store registered with the ``stores`` configuration
    option.}
    'default_store' : string = 'file' with match (SELF,
        '^(file|filesystem|http|https|swift|swift\+http|swift\+https|swift\+config|rbd|sheepdog|cinder|vsphere)$')
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
} = dict();

@documentation {
    list of Glance configuration sections
}
type openstack_glance_config = {
    'DEFAULT' ? openstack_DEFAULTS
    'database' : openstack_database
    'keystone_authtoken' : openstack_keystone_authtoken
    'paste_deploy' : openstack_keystone_paste_deploy
    'glance_store' : openstack_glance_store
};
