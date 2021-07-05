declaration template components/spma/schema-common-yum;

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

type spma_yum_plugin_priorities = {
    'enabled' : boolean = true
    'check_obsoletes' ? boolean
};

type spma_yum_plugin_product_id = {
    'enabled' : boolean = false
};

type spma_yum_plugin_subscription_manager = {
    'enabled' : boolean = false
    'disable_system_repos' ? boolean
};

type spma_yum_plugins = {
    "fastestmirror" ? spma_yum_plugin_fastestmirror
    "versionlock" ? spma_yum_plugin_versionlock
    "priorities" ? spma_yum_plugin_priorities
    "subscription-manager" ? spma_yum_plugin_subscription_manager
    "product-id" ? spma_yum_plugin_product_id
};

type component_spma_common_yum = {
    "proxy" ? legacy_binary_affirmation_string # Enable proxy
    "proxyhost" ? string # comma-separated list of proxy hosts
    "proxyport" ? string # proxy port number
};

@{Simple DNF module structure. To be used as dict, with name as key.
  No profile support, as it is only intended to configure/enable modules.
}
type component_spma_dnf_module_simple = {
    'enable' : boolean = true
    'stream' : string
};
