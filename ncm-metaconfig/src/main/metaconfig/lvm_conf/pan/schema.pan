declaration template metaconfig/lvm_conf/schema;

@{ types for configuring the lvm.conf file @}
include 'pan/types';
type lvm_conf_global_entry = {
    'event_activation' ? long(0..1)
    'io_memory_size' ? long
    'test' ? long(0..1)
    'umask' ? long
    'units' ? string_trimmed
    'si_unit_consistency' ? long(0..1)
    'suffix' ? long(0..1)
    'activation' ? long(0..1)
    'wait_for_locks' ? long(0..1)
    'locking_dir' ? string_trimmed
    'prioritise_write_locks' ? long(0..1)
    'abort_on_internal_errors' ? long(0..1)
    'metadata_read_only' ? long(0..1)
    'mirror_segtype_default' ? string_trimmed with match(SELF, "^(raid1|mirror)$")
    'support_mirrored_mirror_log' ? long(0..1)
    'raid10_segtype_default' ? string_trimmed with match(SELF, "^(raid10|mirror)$")
    'sparse_segtype_default' ? string_trimmed with match(SELF, "^(snapshot|thin)$")
    'lvdisplay_shows_full_device_path' ? long(0..1)
    'use_aio' ? long(0..1)
    'use_lvmlockd' ? long(0..1)
    'lvmlockd_lock_retries' ? string_trimmed
    'sanlock_lv_extend' ? long
    'lvmlockctl_kill_command' ? string_trimmed
    'thin_check_executable' ? string_trimmed
    'thin_dump_executable' ? string_trimmed
    'thin_repair_executable' ? string_trimmed
    'thin_check_options' ? string_trimmed
    'thin_repair_options' ? string_trimmed
    'cache_check_executable' ? string_trimmed
    'cache_dump_executable' ? string_trimmed
    'cache_repair_executable' ? string_trimmed
    'cache_check_options' ? string_trimmed
    'cache_repair_options' ? string_trimmed
    'vdo_format_executable' ? string_trimmed
    'vdo_format_options' ? string_trimmed
    'fsadm_executable' ? string_trimmed
    'system_id_source' ? string_trimmed with match(SELF, "^(none|lvmlocal|uname|appmachineid|machineid|file)$")
    'use_lvmpolld' ? long(0..1)
    'notify_dbus' ? long(0..1)
    # below config only on rhel7 version
    'fallback_to_clustered_locking' ? long(0..1)
    'fallback_to_local_locking' ? long(0..1)
    'fallback_to_lvm1' ? long(0..1)
    'format' ? string_trimmed with match(SELF, "^(lvm1|lvm2)")
    'format_libraries' ? string_trimmed
    'locking_library' ? string_trimmed
    'locking_type' ? long(0..5)
    'lvmetad_update_wait_time' ? long
    'segment_libraries' ? string_trimmed
    'use_lvmetad' ? long(0..1)
};
type lvm_conf_activation_entry = {
    'activation_mode' : string_trimmed with match(SELF, "^(complete|degraded|partial)$")
    'checks' ? long(0..1)
    'udev_sync' ? long(0..1)
    'udev_rules' ? long(0..1)
    'verify_udev_operations' ? long(0..1)
    'retry_deactivation' ? long(0..1)
    'missing_stripe_filler' ? string_trimmed with match(SELF, "^(error|zero)$")
    'use_linear_target' ? long(0..1)
    'reserved_stack' ? long
    'reserved_memory' ? long
    'process_priority' ? long
    'raid_region_size' ? long
    'error_when_full' ? long(0..1)
    'readahead' ? string_trimmed with match(SELF, "^(none|auto)$")
    'raid_fault_policy' ? string_trimmed with match(SELF, "^(warn|allocate)$")
    'mirror_image_fault_policy' ? string_trimmed with match(SELF, "^(remove|allocate|allocate_anywhere)$")
    'mirror_log_fault_policy' ? string_trimmed with match(SELF, "^(remove|allocate|allocate_anywhere)$")
    'snapshot_autoextend_threshold' ? long
    'snapshot_autoextend_percent' ? long
    'thin_pool_autoextend_threshold' ? long
    'thin_pool_autoextend_percent' ? long
    'vdo_pool_autoextend_threshold' ? long
    'vdo_pool_autoextend_percent' ? long
    'use_mlockall' ? long(0..1)
    'monitoring' ? long(0..1)
    'polling_interval' ? long
    'auto_set_activation_skip' ? long(0..1)
};

type lvm_conf_config_entry = {
    'checks' ? long(0..1)
    'abort_on_errors' ? long(0..1)
    'profile_dir' ? string_trimmed
};
type lvm_conf_local_entry = {
    'host_id' ? long(1..2000)
    'system_id' ? string_trimmed
};

type lvm_conf_shell_entry = {
    'history' ? long
};

type lvm_conf_backup_entry = {
    'backup' ? long(0..1)
    'backup_dir' ? string_trimmed
    'archive' ? string_trimmed
    'archive_dir' ? string_trimmed
    'retain_min' ? long
    'retain_days' ? long
};

type lvm_conf_metadata_entry = {
    'check_pv_device_sizes' ? long(0..1)
    'record_lvs_history' ? long(0..1)
    'lvs_history_retention_time' ? long(0..1)
    'pvmetadatacopies' ? long(0..1)
    'vgmetadatacopies' ? long(0..1)
    'pvmetadataignore' ? long(0..1)
    'stripesize' ? long
};

type lvm_conf_dmeventd_entry = {
    'mirror_library' ? string_trimmed
    'raid_library' ? string_trimmed
    'snapshot_library' ? string_trimmed
    'thin_library' ? string_trimmed
    'thin_command' ? string_trimmed
    'vdo_library' ? string_trimmed
    'vdo_command' ? string_trimmed
    'executable' ? string_trimmed
};

type lvm_conf_file = {
    'global' :  lvm_conf_global_entry()
    'activation' ? lvm_conf_activation_entry()
    'config' ? lvm_conf_config_entry()
    'local' ? lvm_conf_local_entry()
    'dmeventd' ? lvm_conf_dmeventd_entry()
    'shell' ? lvm_conf_shell_entry()
    'backup' ? lvm_conf_backup_entry()
    'matadata' ? lvm_conf_metadata_entry()
};
