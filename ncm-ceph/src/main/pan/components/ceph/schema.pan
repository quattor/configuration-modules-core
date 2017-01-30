# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include 'quattor/schema';

@documentation{
    desc = check that the ceph osd names are no ceph reserved paths
    arg = ceph_component type
}
function valid_osd_names = {
    if(!exists(ARGV[0]['clusters'])) { return(true); };
    names = list();

    clusters = ARGV[0]['clusters'];
    foreach (name;cluster;clusters) {
        append(names, name);
    };

    foreach (name;cluster;clusters) {
        foreach (host;hvals;clusters[name]['osdhosts']) {
            foreach (osd;osdvals;clusters[name]['osdhosts'][host]['osds']) {
                foreach (idex;clname;names) {
                    if (match(osd, clname + '-\d+$')){
                        error("Osd path: " + osd + " is a ceph-reserved path!");
                        return(false);
                    };
                };
            };
        };
    };
    return(true);
};

@documentation{
    desc = checks the ceph crushmap, this includes uniqueness of bucket and rule name, recursive bucket typing, and rules using existing buckets
    arg = crushmap allowed bucket types
    arg = crushmap buckets definitions
    arg = rules to traverse crushmap
}
function is_crushmap = {
    names = list();
    types = ARGV[0];
    buckets = ARGV[1];
    rules = ARGV[2];
    #check types
    if(index('osd', types) == -1 || index('host', types) == -1) {
        error("Types should at least contain type 'osd' and 'host'.");
        return(false);
    };
    # check buckets (names, attrs, types)
    foreach(idx;bucket;buckets) {
        if (!is_bucket(bucket, names, types, 1)){
            return(false);
        };
    };
    # check rule names
    rulenames = list();
    foreach(idx;rule;rules) {
        if(index(rule['name'], rulenames) != -1) {
            error("Duplicate rule name " + rule['name']);
            return(false);
        } else {
            append(rulenames, rule['name']);
        };
        foreach(idx;step;rule['steps']) {
            if(index(step['take'], names) == -1) {
                error("rule " + rule['name'] + " selects a non-existing bucket " + step['take']);
                return(false);
            };
        };
    };
    true;
};

@documentation{
    desc = check the bucket type recursively, this includes attribute type and value checking and the uniqueness of names
    arg = bucket to check
    arg = list of already parsed bucket names
    arg = accepted bucket types
    arg = 1 if bucket is top bucket, 0 otherwise
}
function is_bucket = {
    bucket = ARGV[0];
    names = ARGV[1];
    types = ARGV[2];
    top = ARGV[3];
    if(!is_dict(bucket)) {
        error("Invalid bucket! Bucket should be an dict.");
        return(false);
    };
    if(!exists(bucket['name']) || !is_string(bucket['name']) ) {
        error("Invalid bucket! Expected 'name' of type string");
        return(false);
    };
    if(!exists(bucket['type']) || !is_string(bucket['type']) ) {
        error("Invalid bucket! Expected 'type' of type string");
        return(false);
    } else {
        if(index(bucket['type'], types) == -1) {
            error("Invalid bucket type: " + bucket['type'] + " not in crushmap 'types'!");
            return(false);
        };
    };
    if(exists(bucket['alg']) && !is_ceph_crushmap_bucket_alg(bucket['alg'])) {
        error("Bucket attribute 'alg' invalid. Got " + bucket['alg']);
        return(false);
    };
    if(exists(bucket['hash']) && !is_long(bucket['hash'])) {
        error("Bucket attribute 'hash' invalid. Expected long, but got " + bucket['hash']);
        return(false);
    };
    if(exists(bucket['weight']) && (!is_double(bucket['weight']) || bucket['weight'] < 0)) {
        error("Bucket attribute 'weight' invalid. Expected positive double.");
        return(false);
    };
    if(exists(bucket['labels']) && !is_list(bucket['labels'])) {
        error("Invalid labels! Labels should be a list.");
        return(false);
    };
    valids = list('name', 'type', 'alg', 'hash', 'weight', 'buckets', 'labels');
    if(top == 1){
        append(valids, 'defaultalg');
        append(valids, 'defaulthash');
    };
    foreach(attr;val;bucket) {
        if(index(attr, valids) == -1) {
            error("Attribute " + attr + " of bucket not supported!");
            retrun(false);
        };
    };
    cnames = list();
    if(exists(bucket['labels'])) {
        foreach(li;label;bucket['labels']) {
            append(cnames, format('%s-%s', bucket['name'], label));
        };
    } else {
        append(cnames, bucket['name']);
    };
    foreach(ni;cname;cnames) {
        if(index(cname, names) != -1) {
            error("Duplicate bucket name " + cname);
            return(false);
        } else {
            append(names, cname);
        };
        debug("Bucket " + cname);
    };
    # Check attributes

    #recurse if buckets exists
    if(exists(bucket['buckets'])){
        foreach(idx;cbucket;bucket['buckets']) {
            if (!is_bucket(cbucket, names, types, 0)){
                return(false);
            };
        };
    };
    true;
};

@documentation{ ceph daemon config parameters }
type ceph_daemon_config = {
};

@documentation{ type for a generic ceph daemon }
type ceph_daemon = {
    'up' : boolean = true
};

include 'components/ceph/schema-mon';
include 'components/ceph/schema-osd';
include 'components/ceph/schema-mds';
include 'components/ceph/schema-rgw';

@documentation{ ceph cluster-wide config parameters }
type ceph_cluster_config = {
    'auth_client_required' : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'auth_cluster_required' : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'auth_service_required' : string = 'cephx' with match(SELF, '^(cephx|none)$')
    'cluster_network' ? type_network_name
    'enable_experimental_unrecoverable_data_corrupting_features' ? string[1..]
    'filestore_xattr_use_omap' ? boolean
    'fsid' : type_uuid # Should be generated with uuidgen
    'mon_cluster_log_to_syslog' : boolean = true
    'mon_initial_members' : type_network_name [1..]
    'mon_osd_min_down_reporters' ? long(0..)
    'mon_osd_min_down_reports' ? long(0..)
    'mon_osd_max_op_age' ? long = 32
    'ms_type' ? string with match(SELF, '^(simple|async|xio)$')
    'op_queue' ? string with match(SELF, '^(prio|wpq)$')
    # the component sets this to false when generating crushmap itself, and true when crushmap is generated by ceph
    'osd_crush_update_on_start' ? boolean
    'osd_journal_size' : long(0..) = 10240
    'osd_objectstore' ? string
    'osd_pool_default_min_size' : long(0..) = 2
    'osd_pool_default_pg_num' ? long(0..)
    'osd_pool_default_pgp_num' ? long(0..)
    'osd_pool_default_size' : long(0..) = 3
    'public_network' : type_network_name
};

@documentation{
    desc = check it is a valid algorithm, also used in is_crushmap
    arg = bucket algoritm
}
function is_ceph_crushmap_bucket_alg = {
    if (!match(ARGV[0], '^(uniform|list|tree|straw2?)$')){
        error(ARGV[0] +  'is not a valid bucket algorithm');
        return(false);
    };
    true;
};

@documentation{ ceph crushmap bucket definition }
type ceph_crushmap_bucket = {
    'name' : string #Must be unique
    'type' : string # Must be in ceph_crushmap types
    'alg' ? string with is_ceph_crushmap_bucket_alg(SELF)
    'hash' ? long = 0 # 0 is rjenkins1
    'weight' ? double(0..)
    'defaultalg' : string = 'straw' with is_ceph_crushmap_bucket_alg(SELF)
    'defaulthash' : long = 0
    'labels' ? string[1..] # divide hierarchy on a osd label base
    'buckets' ? dict[] # the idea: recursive buckets
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

@documentation{
ceph crushmap definition
The crushmap defines some types of buckets,
a hierarchical bucket structure,
rules for traversing these buckets
and tunables for magic numbers.
}
type ceph_crushmap = {
    'types' : string [1..]
    'buckets' : ceph_crushmap_bucket [1..]
    'rules' : ceph_crushmap_rule[1..]
    'tunables' ? long{}
} with is_crushmap(SELF['types'], SELF['buckets'], SELF['rules']);

@documentation{ overarching ceph cluster type, with osds, mons and msds }
type ceph_cluster = {
    'config' : ceph_cluster_config
    'osdhosts' : ceph_osd_host {}
    'monitors' : ceph_monitor {1..}
    'mdss' ? ceph_mds {}
    'radosgwh' ? ceph_radosgwh {} # gateways are not being deployed yet, only the config
    'deployhosts' : type_fqdn {1..} # key should match value of /system/network/hostname of one or more hosts of the cluster
    'crushmap' ? ceph_crushmap
};

@documentation{
Decentralized config feature:
For use with dedicated pan code that builds the cluster info from remote templates.
}
type ceph_localdaemons = {
    'osds' : ceph_osd {}
};

@documentation{ ceph clusters }
type ${project.artifactId}_component = {
    include structure_component
    'clusters' ? ceph_cluster {}
    'localdaemons' ? ceph_localdaemons # validation, but not used in component code
    'ceph_version' ? string with match(SELF, '[0-9]+\.[0-9]+(\.[0-9]+)?')
    'deploy_version' ? string with match(SELF, '[0-9]+\.[0-9]+\.[0-9]+')
    'key_accept' ? string with match(SELF, '^(first|always)$') # explicit accept host keys
    'ssh_multiplex' : boolean = true
    'max_add_osd_failures_per_host' : long(0..) = 0
} with valid_osd_names(SELF);

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
