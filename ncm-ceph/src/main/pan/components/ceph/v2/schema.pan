# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/v2/schema;

include 'quattor/schema';

@documentation{ type for a generic ceph daemon }
type ceph_daemon = {
};

include 'components/ceph/v2/schema-mon';
include 'components/ceph/v2/schema-osd';
include 'components/ceph/v2/schema-mds';
include 'components/ceph/v2/schema-mgr';
include 'components/ceph/v2/schema-rgw';

include 'components/ceph/v2/schema-cfg';
include 'components/ceph/v2/schema-orch';

@documentation{ overarching ceph cluster type, with osds, mons and msds }
type ceph_cluster = {
    'monitors' : ceph_monitor{3..} # with match
    'mdss' ? ceph_mds{} # with match
    'initcfg' : ceph_configfile
    'configdb' ? ceph_configdb
    'deployhosts' : type_fqdn{1..} # key should match value of /system/network/hostname of one or more hosts of the cluster
    'key_accept' ? choice('first', 'always') # explicit accept host keys
    'ssh_multiplex' : boolean = true
};

@documentation{
Decentralized config feature:
For use with dedicated pan code that builds the cluster info from remote templates.
}
type ceph_daemons = {
    'osds' : ceph_osd{}
    'max_add_osd_failures' : long(0..) = 0
};

type ceph_supported_version = string with match(SELF, '[\d*]+\.[\d*]+(\.[\d*]+)?'); # TODO  minimum 12.2.2
type ceph_deploy_supported_version = string with match(SELF, '\d+\.\d+\.\d+'); # TODO minimum 1.5.39

@documentation{
ceph cluster configuration
we only support node to be in one ceph cluster named ceph
this schema only works with Luminous 12.2.2 and above
When setting release to Octopus (15.2.x), we only need orchestrator and ceph_version
 }
type ${project.artifactId}_component = {
    include structure_component
    'cluster' ? ceph_cluster
    'daemons' ? ceph_daemons
    'config' ? ceph_configfile #deprecated, but can be used for host-based config
    'minconfig' ? ceph_minimal_config #supersedes 'config'
    'ceph_version' : ceph_supported_version
    'deploy_version' ? ceph_deploy_supported_version
    'release' : choice('Luminous', 'Octopus') = 'Luminous'
    'orchestrator' ? ceph_orch
};
