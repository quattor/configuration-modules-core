unique template metaconfig/xinetd/services/rsync;

include 'metaconfig/xinetd/schema';

bind "/software/components/metaconfig/services/{/etc/xinetd.d/rsync}/contents" = xinetd_conf;

"/software/components/metaconfig/services/{/etc/xinetd.d/rsync}" = create('metaconfig/xinetd/metaconfig');

prefix "/software/components/metaconfig/services/{/etc/xinetd.d/rsync}/contents";
"servicename" = "rsync";
"options/server" = "/usr/bin/rsync";
"options/socket_type" = "stream";
"options/wait" = false;
"options/server_args" = "--daemon";
