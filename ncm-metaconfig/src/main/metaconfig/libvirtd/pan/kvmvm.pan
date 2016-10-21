unique template metaconfig/libvirtd/kvmvm;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/libvirt/qemu/vm.xml}/contents" = service_kvmvm;

prefix "/software/components/metaconfig/services/{/etc/libvirt/qemu/vm.xml}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/libvirtd" = "restart";
"module" = "libvirtd/kvmvm";
