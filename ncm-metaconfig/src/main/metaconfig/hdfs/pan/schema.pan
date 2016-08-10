declaration template metaconfig/hdfs/schema;

include 'pan/types';

type hdfs_core_site_fs_defaultFS  = {
    'format' : string with match(SELF, '^(hdfs|viewfs)$')
    'host' : type_hostname
    'port' : long = 9000
};

type hdfs_core_site_fs = {
    'defaultFS' : hdfs_core_site_fs_defaultFS
};

type hdfs_core_site = {
    'fs' : hdfs_core_site_fs
};
 
type hdfs_hdfs_site_datanode = {
    'handler.count' ? long
    'max.transfer.threads' ? long
};

type hdfs_hdfs_site_namenode = {
    'handler.count' ? long
};

type hdfs_hdfs_site = {
    'namenode' ? hdfs_hdfs_site_namenode
    'datanode' ? hdfs_hdfs_site_datanode
};

type hdfs_gpfs_site = {
    'mnt.dir' : string
    'data.dir' ? string
    'supergroup' ? string[]
    'storage.type' : string with match(SELF, '^(shared|local)$')
    'replica.enforced' : string with match(SELF, '^(dfs|gpfs)$')
};

type type_hdfs_slaves = type_hostname[];

type hdfs_service = {
    'core-site' : hdfs_core_site
    'hdfs-site' : hdfs_hdfs_site
    'gpfs-site' ? hdfs_gpfs_site
    'slaves' ? type_hdfs_slaves
};
