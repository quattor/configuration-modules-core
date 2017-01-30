# ${license-info}
# ${developer-info}
# ${author-info}

declaration template quattor/aii/freeipa/schema;

final variable FREEIPA_AII_MODULE_NAME = 'NCM::Component::freeipa';

@documentation{
a function to validate all freeipa hooks
example usage:
    bind "/system/aii/hooks" = dict with validate_aii_freeipa_hooks('post_reboot')
}
function validate_aii_freeipa_hooks = {
    if (ARGC != 1) {
        error(format("%s: requires only one argument", FUNCTION));
    };

    if (! exists(SELF[ARGV[0]])) {
        error(format("%s: no %s hook found.", FUNCTION, ARGV[0]));
    };


    hook = SELF[ARGV[0]];
    found = false;
    ind = 0;
    foreach (i;v;hook) {
        if (exists(v['module']) && v['module'] == FREEIPA_AII_MODULE_NAME) {
            if (found) {
                error(format("%s: second freeipa %s hook found", FUNCTION, name));
            } else {
                found = true;
                ind = i;
            };
        };
    };

    if (! found) {
        error(format("%s: no freeipa %s hook found with module %s", FUNCTION, ARGV[0], FREEIPA_AII_MODULE_NAME));
    };

    true;
};

# TODO: not used; wait till we can use type tests
type aii_freeipa = {
    "module" : string with SELF == FREEIPA_AII_MODULE_NAME

    @{remove the host on AII removal (precedes disable)}
    "remove" : boolean = false
    @{disable the host on AII removal}
    "disable" : boolean = true
};
