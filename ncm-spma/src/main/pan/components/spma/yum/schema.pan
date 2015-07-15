# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/yum/schema;

type component_spma_fastestmirror = {
    'enabled' : boolean = false
    'verbose' : boolean = false
    'always_print_best_host' : boolean = true
    'socket_timeout' : long(0..) = 3
    'hostfilepath' : string = "timedhosts.txt"
    'maxhostfileage' : long(0..) = 10
    'maxthreads' : long(0..) = 15
    'exclude' ? string[]
    'include_only' ? string[]
};

type component_spma_yum = {
    "userpkgs_retry" : boolean = true
    "fullsearch" : boolean = false
    "fastestmirror" ? component_spma_fastestmirror
};
