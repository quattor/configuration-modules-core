# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/v2/schema;

include 'quattor/schema';

@documentation{ type for a generic ceph daemon }
type ceph_daemon = {
};

include 'components/ceph/v2/schema-mon';
include 'components/ceph/v2/schema-osd';
include 'components/ceph/v2/schema-mds';
include 'components/ceph/v2/schema-rgw';

@documentation{ ceph cluster-wide config parameters }
type ceph_global_config = {
    'auth_client_required' : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'auth_cluster_required' : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'auth_service_required' : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'cluster_network' ? type_network_name
    'enable_experimental_unrecoverable_data_corrupting_features' ? string[1..]
    'filestore_xattr_use_omap' ? boolean
    'fsid' : type_uuid # Should be generated with uuidgen
    'mon_cluster_log_to_syslog' : boolean = true
    'mon_initial_members' : type_network_name [1..]
    'mon_host' : type_fqdn[1..]
    'mon_osd_min_down_reporters' ? long(0..)
    'mon_osd_min_down_reports' ? long(0..)
    'mon_osd_max_op_age' ? long = 32
    'ms_type' ? string with match(SELF, '^(simple|async|xio)$')
    'op_queue' ? string with match(SELF, '^(prio|wpq)$')
    'osd_journal_size' : long(0..) = 10240
    'osd_pool_default_min_size' : long(0..) = 2
    'osd_pool_default_pg_num' ? long(0..)
    'osd_pool_default_pgp_num' ? long(0..)
    'osd_pool_default_size' : long(0..) = 3
    'public_network' : type_network_name
};

@documentation{ ceph crushmap rule step }
type ceph_crushmap_rule_choice = {
    'chtype' : string with match(SELF, '^choose(leaf)? (firstn|indep)$')
    'number' : long = 0
    'bktype' : string
};

@documentation{ ceph crushmap rule step }
type ceph_crushmap_rule_step = {
    'take' : string # Should be a valid bucket
    'set_choose_tries' ? long
    'set_chooseleaf_tries' ? long
    'choices' : ceph_crushmap_rule_choice[1..]
};

@documentation{ ceph crushmap rule definition }
type ceph_crushmap_rule = {
    'name' : string #Must be unique
    'type' : string = 'replicated' with match(SELF, '^(replicated|erasure)$')
    'ruleset' ? long(0..) # ONLY set if you want to have multiple rules in the same or existing ruleset
    'min_size' : long(0..) = 1
    'max_size' : long(0..) = 10
    'steps' : ceph_crushmap_rule_step[1..]
};

type ceph_crushmap = {
    'rules' : ceph_crushmap_rule[1..]
};

type ceph_configfile = {
    'global' : ceph_global_config
    'mds' ? ceph_mds_config
    'osd' ? ceph_osd_config
    'mon' ? ceph_mon_config
    'rgw' ? ceph_rgw_config{}
};

@documentation{ overarching ceph cluster type, with osds, mons and msds }
type ceph_cluster = {
#    'osdhosts' ? type_fqdn[]
    'monitors' : ceph_monitor {3..} # with match
    'mdss' ? ceph_mds {} # with match
    'initcfg' : ceph_configfile
    'deployhosts' : type_fqdn {1..} # key should match value of /system/network/hostname of one or more hosts of the cluster
#    'crushmap' ? ceph_crushmap # Not yet supported
    'key_accept' ? string with match(SELF, '^(first|always)$') # explicit accept host keys
    'ssh_multiplex' : boolean = true
};

@documentation{
Decentralized config feature:
For use with dedicated pan code that builds the cluster info from remote templates.
}
type ceph_daemons = {
    'osds' : ceph_osd {}
    'max_add_osd_failures' : long(0..) = 0
};

type ceph_supported_version = string with match(SELF, '[0-9]+\.[0-9]+(\.[0-9]+)?'); # TODO  minimum 12.2.2
type ceph_deploy_supported_version = string with match(SELF, '[0-9]+\.[0-9]+\.[0-9]+'); # TODO minimum 1.5.39

@documentation{ 
ceph cluster configuration
we only support node to be in one ceph cluster
 }
type ${project.artifactId}_component = {
    include structure_component
    'cluster' ? ceph_cluster # Only 1 cluster named ceph supported by component for now
    'daemons' ? ceph_daemons 
    'config' ? ceph_configfile
    'ceph_version' : ceph_supported_version
    'deploy_version' ? ceph_deploy_supported_version
};

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
