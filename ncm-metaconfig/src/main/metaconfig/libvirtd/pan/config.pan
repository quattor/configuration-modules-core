unique template metaconfig/libvirtd/config;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/libvirt/libvirtd.conf}/contents" = service_libvirtd;

prefix "/software/components/metaconfig/services/{/etc/libvirt/libvirtd.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/libvirtd" = "restart";
"module" = "libvirtd/libvirtd";
