object template config;

include 'metaconfig/hdfs/config';

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/contents";

"mnt.dir" = "/gpfs/test";
"data.dir" = "hadoop_data";
"storage.type" = "shared";
"replica.enforced" = "gpfs";

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/core-site.xml}/contents";

'fs/defaultFS' = dict(
    'format', 'hdfs',
    'host', 'storage2204.shuppet.os',
#    'port', 9000,
);

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/hdfs-site.xml}/contents";

'datanode/handler.count' = 40;
'datanode/max.transfer.threads' = 8192;
'namenode/handler.count' = 400;
