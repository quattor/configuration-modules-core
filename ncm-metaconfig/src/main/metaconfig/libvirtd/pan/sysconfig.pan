unique template metaconfig/libvirtd/sysconfig;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/sysconfig/libvirtd}/contents" = service_sysconfig_libvirtd;

prefix "/software/components/metaconfig/services/{/etc/sysconfig/libvirtd}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/libvirtd" = "restart";
"module" = "libvirtd/sysconfig";
