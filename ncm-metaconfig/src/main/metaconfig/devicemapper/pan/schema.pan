declaration template metaconfig/devicemapper/schema;

@{
    devicemapper multipath
}
type multipath_defaults_path_selector = list with match(SELF[0], "^(round-robin|queue-length|service-time)$") &&
    is_long(SELF[1]) && SELF[1] == 0;

type multipath_defaults_features = list with length(SELF) == 2 && is_long(SELF[0]) && is_list(SELF[1]) &&
    SELF[0] == length(SELF[1]) && match(SELF[1][0],'^(queue_if_no_path|no_partitions)$');

type multipath_types_shared = {
    'path_grouping_policy' ? string with match(SELF,'^(failover|multibus|group_by_serial|group_by_prio|group_by_node_name)$') # default multibus
    'path_selector' ?  multipath_defaults_path_selector  # The default path selector algorithm
    'prio' ? string with match(SELF,'^(const|emc|alua|tpg_pref|ontap|rdac|hp_sw|hds)$') # how to get default path prio, default const
    'failback' ? string with match(SELF,'^(immediate|manual|followover)$') || to_long(SELF) > 0 # how to manage path group failback, default manual
    'rr_min_io' ? long(0..) # default 1000
    'rr_min_io_rq' ? long(0..) # default 1
    'rr_weight' ? string
    'no_path_retry' ? string with match(SELF,'^(fail|queue)$') || to_long(SELF) > 0 #  default 0
    'flush_on_last_del' ? boolean # default false
};

type multipath_types_multipaths_only = {
    'reservation_key' ? string
};

type multipath_types_devices_only = {
    'getuid_callout' ? string # default /lib/udev/scsi_id --whitelisted --device=/dev/%n
    'path_checker' ? string with match(SELF,'^(readsector0|tur|emc_clariion|hp_sw|rdac|directio)$') # detemine path state, default readsector0
    'features' ? multipath_defaults_features
    'fast_io_fail_tmo' ? boolean # default false
    'dev_loss_tmo' ? long(0..)
    'retain_attached_hw_handler' ? boolean # default false
    'detect_prio' ? boolean # default false
};

type multipath_multipaths = {
    include multipath_types_shared
    include multipath_types_multipaths_only
    "wwid"  : string
    "alias"  : string
};

type multipath_device_blacklist = {
    "vendor"    : string
    "product"   : string
};

type multipath_device = {
    include multipath_types_shared
    include multipath_types_devices_only
    include multipath_device_blacklist
    "revision" ? string
    "product_blacklist" ? string
    "hardware_handler" ? string with match(SELF[1], "^(emc|alua|hp_sw|rdac)$") && is_long(SELF[0]) && SELF[0] == 1
};

type multipath_blacklist = {
    "wwid"  ? string
    "devnode"  ? string
    "device" ? multipath_device_blacklist
};

type multipath_defaults = {
    include multipath_types_shared
    include multipath_types_multipaths_only
    include multipath_types_devices_only

    'polling_interval' ? long(0..) # path check polling interval (default 5)
    'udev_dir' ? string # default /dev
    'multipath_dir' ? string #  directory where the dynamic shared objects are stored; default is system dependent, commonly /lib/multipath
    'find_multipaths' ? boolean # default false
    'verbosity' ? long(0..6) # default 2
    'user_friendly_names' ? boolean # default false
    'queue_without_daemon' ? boolean # default false
    'max_fds' ? long(0..)
    'checker_timeout' ? long(0..)
    'log_checker_err' ? string with match(SELF,'^(once|always|)$') # default always
    'hwtable_regex_match' ? boolean # default false
};

type multipath_config = {
    "defaults" ? multipath_defaults
    "blacklist" ? multipath_blacklist[]
    "blacklist_exceptions" ? multipath_blacklist[]
    "multipaths" ? multipath_multipaths[]
    "devices" ? multipath_device[]
};
