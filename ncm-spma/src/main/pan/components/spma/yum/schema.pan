# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/yum/schema;

type spma_yum_plugin_fastestmirror = {
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

type spma_yum_plugin_versionlock = {
    'enabled' : boolean = true
    'locklist' : string = '/etc/yum/pluginconf.d/versionlock.list'
    'follow_obsoletes' ? boolean
};

type spma_yum_plugins = {
    "fastestmirror" ? spma_yum_plugin_fastestmirror
    "versionlock" ? spma_yum_plugin_versionlock
};

type component_spma_yum = {
    "userpkgs_retry" : boolean = true
    "fullsearch" : boolean = false
    "plugins" ? spma_yum_plugins
};
