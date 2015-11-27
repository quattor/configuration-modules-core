declaration template metaconfig/cgroups/schema;

include 'pan/types';

type cgroups_cgrule_user = {
    'name' ? string with match(SELF, '^(?!(\*|%|@)).+') # user name only
    'group' ? string # @group
    'ditto' ? boolean with SELF # %, makes no sense if it's false
    'any' ? boolean with SELF # *, makes no sense if it's false
} with {
    if (! (length(SELF) == 1)) {
        error(format('One and only one attribute must be defined (got %s)', to_string(SELF)));
    };
    true;
};

@{controllers from /proc/cgroups or named hierarchy}
type cgroups_controller = string with match(SELF, '^(\*|cpu(acct|set)?|memory|ns|devices|freezer|net_cls|blkio|perf_event|net_prio|hugetlb|name=\S+)$'); 

@{Type for a single cgrule. Contents should be a list of these.}
type cgroups_cgrule = {
    'user' : cgroups_cgrule_user
    'process' ? string
    'controllers' : cgroups_controller[]
    'destination' : string with match(SELF, '^(?!/).') # relative path
};

type cgroups_cgconfig_mount = {
    'controller' : cgroups_controller
    'path' : string # TODO: relative path?
};

type cgroups_cgconfig_group = {
    'name' : string
};

type cgroups_cgconfig_default = {
};

type cgroups_cgconfig_service = {
    'mount' ? cgroups_cgconfig_mount[]
    'group' ? cgroups_cgconfig_group{}
    'default' ? cgroups_cgconfig_default
};
