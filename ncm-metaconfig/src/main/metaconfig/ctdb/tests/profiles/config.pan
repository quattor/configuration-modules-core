object template config;

include 'metaconfig/ctdb/config';

variable FULL_HOSTNAME = 'storage2201.example.com';
prefix "/software/components/metaconfig/services/{/etc/sysconfig/ctdb}/contents/service";

"ctdb_debuglevel" = 2;
"ctdb_manages_nfs" = true;
"ctdb_manages_samba"= false;
"ctdb_nfs_skip_share_check" = true;
"ctdb_public_addresses" = '/etc/ctdb/public_addresses';
"ctdb_recovery_lock" = "/gpfs/scratchtest/home/ctdb/lock/file";
"ctdb_syslog" = true;
"nfs_hostname" = FULL_HOSTNAME;
"nfs_server_mode" = 'ganesha';
"prologue" = "/usr/bin/waitforgpfs.sh /dev/scratchtest\nulimit -n 10000";
