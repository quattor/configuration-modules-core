object template config;

include 'metaconfig/hadoop/config';


bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}/contents" = hadoop_core_site;
bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}/contents/dfs" = hadoop_hdfs_site;
bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}/contents" = type_hdfs_slaves;
bind "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/contents/gpfs" = hadoop_gpfs_site;

prefix "/software/components/metaconfig/services";

"{/etc/hadoop/conf.quattor/hdfs-site.xml}/module" = "hadoop/main";
"{/etc/hadoop/conf.quattor/core-site.xml}/module" = "hadoop/main";
"{/etc/hadoop/conf.quattor/slaves}/module" = "hadoop/slaves";
"{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/module" = "hadoop/main";

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/contents/gpfs";

"mnt.dir" = "/gpfs/test";
"data.dir" = "hadoop_data";
"storage.type" = "shared";
"replica.enforced" = "gpfs";

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}/contents";

'fs/defaultFS' = dict(
    'format', 'hdfs',
    'host', 'storage2204.shuppet.os',
#    'port', 9000,
);

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}/contents/dfs";

'namenode/handler.count' = 400;
prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}/contents/dfs/datanode";
'handler.count' = 40;
'max.transfer.threads' = 8192;
'address'  = 'localhost:50010';
'ipc.address' ='localhost:50020';
'http.address' = 'localhost:50075';
'https.address' = 'localhost:50475';

"/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}/contents" = list('localhost', 'remotehost');
