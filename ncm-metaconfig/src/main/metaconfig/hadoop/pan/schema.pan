declaration template metaconfig/hadoop/schema;

include 'pan/types';

type hadoop_core_site_fs_defaultFS  = {
    'format' : string with match(SELF, '^(hdfs|viewfs)$')
    'host' : type_hostname
    'port' : long = 9000
};

type hadoop_core_site_fs = {
    'defaultFS' : hadoop_core_site_fs_defaultFS
};

type hadoop_core_site = {
    'fs' : hadoop_core_site_fs
};
 
type hadoop_hdfs_site_datanode = {
    'handler.count' ? long
    'max.transfer.threads' ? long
};

type hadoop_hdfs_site_namenode = {
    'handler.count' ? long
};

type hadoop_hdfs_site = {
    'namenode' ? hadoop_hdfs_site_namenode
    'datanode' ? hadoop_hdfs_site_datanode
};

type hadoop_gpfs_site = {
    'mnt.dir' : string
    'data.dir' ? string
    'supergroup' ? string[]
    'storage.type' : string with match(SELF, '^(shared|local)$')
    'replica.enforced' : string with match(SELF, '^(dfs|gpfs)$')
};

type type_hdfs_slaves = type_hostname[];

type hadoop_service = {
    'core-site' : hadoop_core_site
    'hdfs-site' : hadoop_hdfs_site
    'gpfs-site' ? hadoop_gpfs_site
    'slaves' ? type_hdfs_slaves
};
