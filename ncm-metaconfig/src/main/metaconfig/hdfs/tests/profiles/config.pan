object template config;

variable GPFS_HDFS_TRANSPARANCY = true;
include 'metaconfig/hdfs/config';

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

'datanode/handler.count' = 40;
'datanode/max.transfer.threads' = 8192;
'namenode/handler.count' = 400;

#"/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}/contents" = list('localhost', 'remotehost');
