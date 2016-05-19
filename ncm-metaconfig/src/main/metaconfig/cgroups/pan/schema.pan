declaration template metaconfig/cgroups/schema;

include 'pan/types';
include 'components/accounts/functions';

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
function is_cgroups_controller = {
    match(ARGV[0], '^(\*|cpu(acct|set)?|memory|ns|devices|freezer|net_cls|blkio|perf_event|net_prio|hugetlb|name=\S+)$');
};

type cgroups_controller = string with is_cgroups_controller(SELF);

@{Type for a single cgrule. Contents should be a list of these.}
type cgroups_cgrule = {
    'user' : cgroups_cgrule_user
    'process' ? string
    'controllers' : cgroups_controller[]
    'destination' : string with match(SELF, '^(?!/).') # relative path
};

type cgroups_cgconfig_permissions_task = {
    'uid' ? defined_user
    'gid' ? defined_group
    'fperm' ? string with match(SELF, '[0-7]{3}')
};

type cgroups_cgconfig_permissions_admin = {
    include cgroups_cgconfig_permissions_task
    'dperm' ? string with match(SELF, '[0-7]{3}')
};

type cgroups_cgconfig_permissions = {
    'task' ? cgroups_cgconfig_permissions_task
    'admin' ? cgroups_cgconfig_permissions_admin
};

type cgroups_cgconfig_mount = string{} with {
    foreach (contr;value;SELF) {
        controller = unescape(contr);
        if (! is_cgroups_controller(controller)) {
            error(format('Invalid cgroups cgconfig mount controller %s', controller));
        };
    };
    true;
};

type cgroups_cgconfig_controllers = string{}{} with {
    foreach (contr;value;SELF) {
        controller = unescape(contr);
        if (! is_cgroups_controller(controller)) {
            error(format('Invalid cgroups cgconfig controller %s', controller));
        };
    };
    true;
};

type cgroups_cgconfig_group = {
    'perm' ? cgroups_cgconfig_permissions
    'controllers' ? cgroups_cgconfig_controllers
};

type cgroups_cgconfig_default = {
    'perm' ? cgroups_cgconfig_permissions
};

type cgroups_cgconfig_service = {
    'mount' ? cgroups_cgconfig_mount
    'group' ? cgroups_cgconfig_group{}
    'template' ? cgroups_cgconfig_group{}
    'default' ? cgroups_cgconfig_default
};
