unique template metaconfig/rsync/daemon;

include 'metaconfig/rsync/schema';

bind "/software/components/metaconfig/services/{/etc/rsyncd.conf}/contents" = rsync_file;

prefix "/software/components/metaconfig/services/{/etc/rsyncd.conf}";
"module" = "rsync/daemon";

prefix "/software/components/metaconfig/services/{/etc/rsyncd.conf}/contents";
"log" = "/var/log/rsyncd";
"facility" = "daemon";
