unique template metaconfig/libvirtd/config;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/libvirt/libvirtd.conf}/contents" = structure_component_libvirtd;

prefix "/software/components/metaconfig/services/{/etc/libvirt/libvirtd.conf}";
"daemons" = dict(
    "libvirtd", "restart",
);
"module" = "libvirtd/libvirtd";
