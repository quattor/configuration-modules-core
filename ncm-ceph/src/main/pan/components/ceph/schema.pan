# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include { 'quattor/schema' };

function check_osd_names = {
    names = list();
    clusters = ARGV[0]['clusters'];
    foreach (name;cluster;clusters) {
        append(names, name);
    };

    foreach (name;cluster;clusters) {
        foreach (host;hvals;clusters[name]['osdhosts']) {
            foreach (osd;osdvals;clusters[name]['osdhosts'][host]['osds']) {
                foreach (idex;clname;names) {
                    if (match(osd,clname + '-\d+$')){
                        error("Osd path: " + osd + " is a ceph-reserved path!"); 
                        return(false);
                    };
                };
            };
        };
    };
   return(true);
};
@{ type for a generic ceph daemon @}
type ceph_daemon = {
    'up'    : boolean = true
};

@{ ceph monitor-specific type @}
type ceph_monitor = {
    include ceph_daemon
    'fqdn'  : type_fqdn
};

@{ 
ceph osd-specific type 
The key of the ceph_osd should be the path to the mounted disk. 
This can be an absolute path or a relative one to /var/lib/ceph/osd/
journal_path should be the path to a journal file
This can be an absolute path or a relative one to /var/lib/ceph/log/
@}
type ceph_osd = {
    include ceph_daemon
    'in'            ? boolean = true
    'journal_path'  ? string
};

@{ ceph osdhost-specific type @}
type ceph_osd_host = {
    'fqdn'          : type_fqdn
    'osds'          : ceph_osd {}
};

@{ ceph mds-specific type @}
type ceph_mds = {
     include ceph_daemon
    'fqdn'  : type_fqdn
};

@{ ceph cluster-wide config parameters @}
type ceph_cluster_config = {
    'fsid'                      : string
    'filestore_xattr_use_omap'  : boolean = true
    'osd_journal_size'          : long(0..) = 10240
    'mon_initial_members'       : string [1..]
    'public_network'            : string with match(SELF,'^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$')
    'cluster_network'           ? string with match(SELF,'^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$')
    'auth_service_required'     : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'auth_client_required'      : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'auth_cluster_required'     : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'osd_pool_default_pg_num'   : long(0..) = 600
    'osd_pool_default_pgp_num'  : long(0..) = 600
    'osd_pool_default_size'     : long(0..) = 2
    'osd_pool_default_min_size' : long(0..) = 1
};

@{ overarching ceph cluster type, with osds, mons and msds @}
type ceph_cluster = {
    'config'                    : ceph_cluster_config
    'osdhosts'                  : ceph_osd_host {}
    'monitors'                  : ceph_monitor {1..}
    'mdss'                      ? ceph_mds {}
    'deployhosts'               : type_fqdn {1..}
};

@{ ceph clusters @}
type ${project.artifactId}_component = {
    include structure_component
    'clusters'         : ceph_cluster {}
    'ceph_version'     ? string with match(SELF, '[0-9]+\.[0-9]+\.[0-9]+')
    'deploy_version'   ? string with match(SELF, '[0-9]+\.[0-9]+\.[0-9]+')
} with check_osd_names(SELF);

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
