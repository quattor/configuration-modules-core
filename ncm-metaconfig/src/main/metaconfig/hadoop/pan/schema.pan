declaration template metaconfig/hadoop/schema;

include 'pan/types';

@{ type for the fs.defaultFS setting of the core-site.xml hadoop file @}
type hadoop_core_site_fs_defaultFS  = {
    'format' : string with match(SELF, '^(hdfs|viewfs)$')
    'host' : type_hostname
    'port' : long = 9000
};

@{ fs settings of the core-site.xml hadoop file @}
type hadoop_core_site_fs = {
    'defaultFS' : hadoop_core_site_fs_defaultFS
};

@{ settings for the core-site.xml hadoop file @}
type hadoop_core_site = {
    'fs' : hadoop_core_site_fs
};

@{ datanode settings of the hdfs-site.xml hadoop file @}
type hadoop_hdfs_site_datanode = {
    'handler.count' ? long
    'address' ? type_hostport = '0.0.0.0:50010'
    'ipc.address' ? type_hostport = '0.0.0.0:50020'
    'http.address' ? type_hostport = '0.0.0.0:50075'
    'https.address' ? type_hostport = '0.0.0.0:50475'
    'max.transfer.threads' ? long
};

@{ namenode settings of the hdfs-site.xml hadoop file @}
type hadoop_hdfs_site_namenode = {
    'handler.count' ? long
};

@{ settings for the hdfs-site.xml hadoop file @}
type hadoop_hdfs_site = {
    'namenode' ? hadoop_hdfs_site_namenode
    'datanode' ? hadoop_hdfs_site_datanode
};

@{ settings for the gpfs-site.xml file @}
type hadoop_gpfs_site = {
    'mnt.dir' : string
    'data.dir' ? string
    'supergroup' ? string[]
    'storage.type' : string with match(SELF, '^(shared|local)$')
    'replica.enforced' : string with match(SELF, '^(dfs|gpfs)$')
};

@{ contents of hadoop slaves file @}
type type_hdfs_slaves = type_hostname[];

@{ type for hadoop configuration @}
type hadoop_service = {
    'core-site' : hadoop_core_site
    'hdfs-site' : hadoop_hdfs_site
    'gpfs-site' ? hadoop_gpfs_site
    'slaves' ? type_hdfs_slaves
};
