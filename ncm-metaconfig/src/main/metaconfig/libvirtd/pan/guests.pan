unique template metaconfig/libvirtd/guests;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/sysconfig/libvirt-guests}/contents" = service_sysconfig_guests;

prefix "/software/components/metaconfig/services/{/etc/sysconfig/libvirt-guests}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/libvirtd" = "restart";
"module" = "libvirtd/guests";
