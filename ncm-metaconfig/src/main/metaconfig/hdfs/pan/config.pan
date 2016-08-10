unique template metaconfig/hdfs/config;

include 'metaconfig/hdfs/schema';

bind "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}/contents" = hdfs_gpfs_site;
bind "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/core-site.xml}/contents" = hdfs_core_site;
bind "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/hdfs-site.xml}/contents" = hdfs_hdfs_site;
#bind "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/slaves}/contents" = hdfs_slaves;

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/gpfs-site.xml}";
#"daemons" = dict(
#    "exampled", "restart",
#);
"module" = "hdfs/gpfs-site";

prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/hdfs-site.xml}";
"module" = "hdfs/hdfs-site";
prefix "/software/components/metaconfig/services/{/usr/lpp/mmfs/hadoop/etc/hadoop/core-site.xml}";
"module" = "hdfs/core-site";
