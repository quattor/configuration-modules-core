unique template metaconfig/libvirtd/sasl2;

include 'metaconfig/libvirtd/schema';

bind "/software/components/metaconfig/services/{/etc/sasl2/libvirt.conf}/contents" = service_sasl2;

prefix "/software/components/metaconfig/services/{/etc/sasl2/libvirt.conf}";
"mode" = 0644;
"owner" = "root";
"group" = "root";
"daemons/libvirtd" = "restart";
"module" = "libvirtd/sasl2";
