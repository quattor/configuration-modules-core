# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/chkconfig/schema;

include 'quattor/types/component';

function chkconfig_allow_combinations = {
    # Check if certain combinations of service_types are allowed
    # Return true if they are allowed, throws an error otherwise

    if ( ARGC != 1 || ! is_dict(ARGV[0]) ) {
        error('chkconfig_allow_combinations requires 1 dict as argument');
    };
    service = ARGV[0];

    # A mapping between chkconfig service_types that the component will
    # prefer over other service_types. The ones listed here are considered
    # dangerous.
    # Others combinations are still allowed (eg combining del and off,
    # where del will be preferred)
    svt_map = dict(
        'del', list("add", "on", "reset"),
        'off', list("on", "reset"),
        'on', list("reset"),
    );
    foreach(win_svt;svt_list;svt_map) {
        if (exists(service[win_svt])) {
            foreach(idx;svt;svt_list) {
                if (exists(service[svt])) {
                    error(format("Cannot combine '%s' with '%s' (%s would win).", win_svt, svt, win_svt));
                };
            };
        };
    };
    true;
};

type service_type = {
    "name" ? string
    "add" ? boolean
    "del" ? boolean
    "on" ? string
    "off" ? string
    "reset" ? string
    "startstop" ? boolean
} with chkconfig_allow_combinations(SELF);

type component_chkconfig_type = {
    include structure_component
    "service" : service_type{}
    "default" ? string with match (SELF, '^(ignore|off)$')
};
