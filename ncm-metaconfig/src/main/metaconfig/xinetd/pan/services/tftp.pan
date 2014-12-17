unique template metaconfig/xinetd/services/tftp;

include 'metaconfig/xinetd/schema';

bind "/software/components/metaconfig/services/{/etc/xinetd.d/tftp}/contents" = xinetd_conf;

"/software/components/metaconfig/services/{/etc/xinetd.d/tftp}" = create('metaconfig/xinetd/metaconfig');

prefix "/software/components/metaconfig/services/{/etc/xinetd.d/tftp}/contents";
"servicename" = "tftp";
"options/server" = "/usr/sbin/in.tftpd";
"options/protocol" = "udp";
"options/socket_type" = "dgram";
"options/flags" = list("IPv4");
