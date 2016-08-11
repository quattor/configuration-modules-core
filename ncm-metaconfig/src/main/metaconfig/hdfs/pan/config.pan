unique template metaconfig/hdfs/config;

include 'metaconfig/hdfs/schema';

variable GPFS_HDFS_TRANSPARANCY ?= false;

bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}/contents" = hdfs_core_site;
bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}/contents/dfs" = hdfs_hdfs_site;
#bind "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}/contents" = type_hdfs_slaves;

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/hdfs-site.xml}";
"module" = "hdfs/main";
prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}";
"module" = "hdfs/main";
#prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/slaves}";
#"module" = "hdfs/list"; # TODO metaconfig convert option?

include if(GPFS_HDFS_TRANSPARANCY) {
    'metaconfig/hdfs/gpfs';
};
