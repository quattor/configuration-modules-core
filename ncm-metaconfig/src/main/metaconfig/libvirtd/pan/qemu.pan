unique template metaconfig/libvirtd/qemu;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/libvirt/qemu.conf}/contents" = service_qemu;

prefix "/software/components/metaconfig/services/{/etc/libvirt/qemu.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/libvirtd" = "restart";
"module" = "libvirtd/libvirtd";
