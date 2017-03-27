# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/icinga/schema;

include 'quattor/types/component';
include 'pan/types';

# Please note that the "use" directive is not supported in order to make
# validation code easier. If you want hosts to inherit settings then use
# Pan statements like create ("...") or value ("...")

type icinga_hoststring =  string with exists ("/software/components/icinga/hosts/" + SELF) ||
    SELF == "*" || SELF == 'dummy';

type icinga_hostgroupstring = string with exists ("/software/components/icinga/hostgroups/" + escape(SELF)) ||
    SELF == "*";

type icinga_commandstrings = string [] with exists ("/software/components/icinga/commands/" + SELF[0]);

type icinga_timeperiodstring = string with exists ("/software/components/icinga/timeperiods/" + SELF) ||
    SELF == "*";

type icinga_contactgroupstring = string with exists ("/software/components/icinga/contactgroups/" + SELF) ||
    SELF == "*";

type icinga_contactstring = string with exists ("/software/components/icinga/contacts/" + SELF) ||
    SELF == "*";

type icinga_servicegroupstring = string with exists ("/software/components/icinga/servicegroups/" + SELF) ||
    SELF == "*";

type icinga_servicestring = string with exists ("/software/components/icinga/services/" + SELF) ||
    SELF == "*";

type icinga_service_notification_string = string with match (SELF, "^(w|u|c|r|f)$");
type icinga_host_notification_string = string with match (SELF, "^(d|u|r|f)$");
type icinga_stalking_string = string with match (SELF, "^(o|w|u|c)$");
type icinga_execution_failure_string = string with match (SELF, "^(o|w|u|c|p|n)$");
type icinga_notification_failure_string = string with match (SELF, "^(o|w|u|c|p|n)$");

type structure_icinga_host_generic = {
    "name" ? string # Used instead of alias when it s a template declaration
    "check_command" : icinga_commandstrings
    "max_check_attempts" : long
    "check_interval" ? long
    "active_checks_enabled" ? boolean
    "passive_checks_enabled" ? boolean
    "check_period" : icinga_timeperiodstring
    "obsess_over_host" ? boolean
    "check_freshness" ? boolean
    "freshness_threshold" ? long
    "event_handler" ? icinga_commandstrings
    "event_handler_enabled" ? boolean
    "low_flap_threshold" ? long
    "high_flap_threshold" ? long
    "flap_detection_enabled" : boolean = true
    "process_perf_data" ? boolean
    "retain_status_information" ? boolean
    "retain_nonstatus_information" ? boolean
    "contact_groups" : icinga_contactgroupstring[]
    "notification_interval" : long
    "notification_period" : icinga_timeperiodstring
    "notification_options" : icinga_host_notification_string []
    "notifications_enabled" ? boolean
    "stalking_options" ? string with match (SELF, "^(o|d|u)$")
    "register" : boolean = true
} = dict();


# Host definition.
type structure_icinga_host = {
    "alias" : string
    "use" ? string # Used to insert a template host declaration
    "address" ? type_ip # If not present, gethostbyname will be used.
    "parents" ? icinga_hoststring[]
    "hostgroups" ? icinga_hostgroupstring[]
    "check_command" : icinga_commandstrings
    "max_check_attempts" : long
    "check_interval" ? long
    "active_checks_enabled" ? boolean
    "passive_checks_enabled" ? boolean
    "check_period" : icinga_timeperiodstring
    "obsess_over_host" ? boolean
    "check_freshness" ? boolean
    "freshness_threshold" ? long
    "event_handler" ? icinga_commandstrings
    "event_handler_enabled" ? boolean
    "low_flap_threshold" ? long
    "high_flap_threshold" ? long
    "flap_detection_enabled" : boolean = true
    "process_perf_data" ? boolean
    "failure_prediction_enabled" ? boolean = true
    "retain_status_information" ? boolean
    "retain_nonstatus_information" ? boolean
    "contact_groups" : icinga_contactgroupstring[]
    "notification_interval" : long
    "notification_period" : icinga_timeperiodstring
    "notification_options" : icinga_host_notification_string []
    "notifications_enabled" ? boolean
    "stalking_options" ? string with match (SELF, "^(o|d|u)$")
    "register" : boolean = true
    "action_url" ? string
    "notes" ? string[]
    "notes_url" ? string
    "_mgmt" ? string
    "_mgmtip" ? string
    "_quattorserver" ? string
    "_quattorserverip" ? string
    "_dimms" ? string
    "_cpus" ? string
    "_enclosureip" ? string
    "_enclosureslot" ? long
} = dict();

# Hostgroup definition
type structure_icinga_hostgroup = {
    "alias" : string
    "members" ? icinga_hoststring[]
} = dict();

# Host dependency definition
type structure_icinga_hostdependency = {
    "dependent_host_name" : icinga_hoststring # Should be string[]?
    "notification_failure_criteria" : icinga_host_notification_string[]
} = dict();

# Service definition
type structure_icinga_service = {
    "name" ? string # Used when it s a template declaration
    "use" ? string # Used to include template
    "host_name" ? icinga_hoststring[]
    "hostgroup_name" ? icinga_hostgroupstring[]
    "servicegroups" ? icinga_servicegroupstring []
    "is_volatile" ? boolean
    "check_command" ? icinga_commandstrings
    "max_check_attempts" : long
    "check_interval" : long
    "retry_interval" : long
    "active_checks_enabled" ? boolean
    "passive_checks_enabled" ? boolean
    "check_period" ? icinga_timeperiodstring
    "parallelize_check" ? boolean
    "obsess_over_service" ? boolean
    "check_freshness" ? boolean
    "freshness_threshold" ? long
    "event_handler" ? icinga_commandstrings
    "event_handler_enabled" ? boolean
    "low_flap_threshold" ? long
    "high_flap_threshold" ? long
    "flap_detection_enabled" : boolean = true
    "process_perf_data" ? boolean
    "retain_status_information" ? boolean
    "retain_nonstatus_information" ? boolean
    "notification_interval" : long
    "notification_period" : icinga_timeperiodstring
    "notification_options" : icinga_service_notification_string []
    "notifications_enabled" ? boolean
    "contact_groups" : icinga_contactgroupstring[]
    "stalking_options" ? icinga_stalking_string[]
    "register" : boolean = true
    "failure_prediction_enabled" ? boolean
    "action_url" ? string
} with icinga_has_host_or_hostgroup (SELF);

# Servicegroup definition:
type structure_icinga_servicegroup = {
    "alias" : string
    "members" ? icinga_servicestring []
    "servicegroup_members" ? icinga_servicegroupstring[]
    "notes" ? string
    "notes_url" ? type_absoluteURI
    "action_url" ? type_absoluteURI
} = dict();

# Servicedependency definition:
type structure_icinga_servicedependency = {
    "dependent_host_name" : icinga_hoststring[]
    "dependent_hostgroup_name" ? icinga_hostgroupstring[]
    "dependent_service_description" : icinga_servicestring
    "host_name" ? icinga_hoststring
    "hostgroup_name" ? icinga_hostgroupstring
    "service_description" : string
    "inherits_parent" ? boolean
    "execution_failure_criteria" ? icinga_execution_failure_string []
    "notification_failure_criteria" ? icinga_notification_failure_string []
    "dependency_period" ? icinga_timeperiodstring
} with icinga_has_host_or_hostgroup (SELF);

# Contact definition
type structure_icinga_contact = {
    "alias" : string
    "contactgroups" ? icinga_contactgroupstring []
    "host_notification_period" : icinga_timeperiodstring
    "service_notification_period" : icinga_timeperiodstring
    "host_notification_options" : icinga_host_notification_string []
    "service_notification_options" : icinga_service_notification_string []
    "host_notification_commands" : icinga_commandstrings []
    "service_notification_commands" : icinga_commandstrings []
    "email" : string
    "pager" ? string
} = dict();

# Contact group definition
type structure_icinga_contactgroup = {
    "alias" : string
    "members" : icinga_contactstring[]
} = dict();

# Time range definition
type icinga_timerange = string with
    match (SELF, "^(([0-9]+:[0-9]+)-([0-9]+:[0-9]+),)*([0-9]+:[0-9]+)-([0-9]+:[0-9]+)$");

# Time period definition
type structure_icinga_timeperiod = {
    "alias" ? string
    "monday" ? icinga_timerange
    "tuesday" ? icinga_timerange
    "wednesday" ? icinga_timerange
    "thursday" ? icinga_timerange
    "friday" ? icinga_timerange
    "saturday" ? icinga_timerange
    "sunday" ? icinga_timerange
} = dict();

# Extended information for services
type structure_icinga_serviceextinfo = {
    "host_name" ? icinga_hoststring[]
    "service_description" : string
    "hostgroup_name" ? icinga_hostgroupstring[]
    "notes" ? string
    "notes_url" ? type_absoluteURI
    "action_url" ? type_absoluteURI
    "icon_image" ? string
    "icon_image_alt" ? string
} with icinga_has_host_or_hostgroup (SELF);

# CGI configuration
type structure_icinga_cgi_cfg = {
    "main_config_file" : string = "/etc/icinga/icinga.cfg"
    "physical_html_path" : string = "/usr/share/icinga"
    "url_html_path" : string = "/icinga"
    "url_stylesheets_path" : string = "/icinga/stylesheets"
    "http_charset" : string = "utf-8"
    "show_context_help" : boolean = false
    "highlight_table_rows" : boolean = false
    "use_pending_states" : boolean = true
    "use_logging" : boolean = false
    "cgi_log_file" : string = "/var/log/icinga/gui/icinga-cgi.log"
    "cgi_log_rotation_method" : string = "d"
    "cgi_log_archive_path" : string = "/var/log/icinga/gui"
    "enforce_comments_on_actions" : boolean = false
    "first_day_of_week" : boolean = false
    "use_authentication" : boolean = true
    "use_ssl_authentication": boolean = false
    "authorized_for_system_information" : string = "icingaadmin"
    "authorized_for_configuration_information" : string = "icingaadmin"
    "authorized_for_system_commands" : string = "icingaadmin"
    "authorized_for_all_services" : string = "icingaadmin"
    "authorized_for_all_hosts" : string = "icingaadmin"
    "authorized_for_all_service_commands" : string = "icingaadmin"
    "authorized_for_all_host_commands" : string = "icingaadmin"
    "show_all_services_host_is_authorized_for": boolean = true
    "show_partial_hostgroups" : boolean = false
    "statusmap_background_image" ? string
    "default_statusmap_layout" : long = 5
    "default_statuswrl_layout" : long = 4
    "statuswrl_include" ? string
    "ping_syntax" : string = "/bin/ping -n -U -c 5 $HOSTADDRESS$"
    "refresh_rate" : long = 90
    "escape_html_tags" : boolean = true
    "persistent_ack_comments" : boolean = false
    "action_url_target" : string = "main"
    "notes_url_target" : string = "main"
    "lock_author_names" : boolean = true
    "default_downtime_duration" : long = 7200
    "status_show_long_plugin_output": boolean = false
    "tac_show_only_hard_state": boolean = false
    "suppress_maintenance_downtime" : boolean = false
    "show_tac_header" : boolean = true
    "show_tac_header_pending" : boolean = true
    "tab_friendly_titles" : boolean = true
    "default_expiring_acknowledgement_duration" ? long
    "default_expiring_disabled_notifications_duration" ? long
    "display_status_totals" ? boolean
    "extinfo_show_child_hosts" ? long
    "log_file" ? string
    "log_rotation_method" ? string
    "lowercase_user_name" ? boolean
    "result_limit" ? long
    "send_ack_notifications" ? boolean
    "set_expire_ack_by_default" ? boolean
    "standalone_installation" ? boolean
} = dict();

# General options
type structure_icinga_icinga_cfg = {
    "log_file" : string = "/var/log/icinga/icinga.log"
    "object_cache_file" : string = "/var/icinga/objects.cache"
    "resource_file" : string = "/etc/icinga/resource.cfg"
    "status_file" : string = "/var/icinga/status.dat"
    "icinga_user" : string = "icinga"
    "icinga_group" : string = "icinga"
    "check_external_commands" : boolean = false
    "command_check_interval" : long = -1
    "command_file" : string = "/var/icinga/rw/icinga.cmd"
    "external_command_buffer_slots" : long = 4096
    "lock_file" : string = "/var/icinga/icinga.pid"
    "temp_file" : string = "/var/icinga/icinga.tmp"
    "event_broker_options" : long = -1
    "log_rotation_method" : string = "d"
    "log_archive_path" : string = "/var/log/icinga/archives"
    "use_syslog" : boolean = true
    "log_notifications" : boolean = true
    "log_service_retries" : boolean = true
    "log_host_retries" : boolean = true
    "log_event_handlers" : boolean = true
    "log_initial_states" : boolean = false
    "log_current_states" : boolean = true
    "log_external_commands" : boolean = true
    "log_passive_checks" : boolean = true
    "log_external_commands_user" ? boolean = false with {
                deprecated(0, 'removed in recent versions of icinga 1.X'); true; }
    "log_long_plugin_output" : boolean = false
    "global_host_event_handler" ? string
    "service_inter_check_delay_method" : string = "s"
    "max_service_check_spread" : long = 30
    "service_interleave_factor" : string = "s"
    "host_inter_check_delay_method" : string = "s"
    "max_host_check_spread" : long = 30
    "max_concurrent_checks" : long = 0
    "service_reaper_frequency" : long = 10
    "check_result_buffer_slots" ? long
    "auto_reschedule_checks" : boolean = false
    "auto_rescheduling_interval" : long = 30
    "auto_rescheduling_window" : long = 180
    "sleep_time" : string = "0.25"
    "service_check_timeout" : long = 40
    "host_check_timeout" : long = 20
    "event_handler_timeout" : long = 30
    "notification_timeout" : long = 30
    "ocsp_timeout" : long = 5
    "perfdata_timeout" : long = 5
    "retain_state_information" : boolean = true
    "state_retention_file" : string = "/var/icinga/retention.dat"
    "retention_update_interval" : long = 60
    "use_retained_program_state" : boolean = true
    "dump_retained_host_service_states_to_neb" : boolean = true
    "use_retained_scheduling_info" : boolean = false
    "interval_length" : long = 60
    "use_aggressive_host_checking" : boolean = false
    "execute_service_checks" : boolean = true
    "accept_passive_service_checks" : boolean = false
    "execute_host_checks" : boolean = true
    "accept_passive_host_checks" : boolean = true
    "enable_notifications" : boolean = true
    "enable_event_handlers" : boolean = true
    "process_performance_data" : boolean = true
    "service_perfdata_command" : icinga_commandstrings = list("process-service-perfdata")
    "host_perfdata_command" : icinga_commandstrings = list("process-host-perfdata")
    "host_perfdata_file" : string = "/var/icinga/host-perf.dat"
    "service_perfdata_file" : string = "/var/icinga/service-perf.dat"
    "host_perfdata_file_template" : string = "[HOSTPERFDATA]\t$TIMET$\t$HOSTNAME$\t$HOSTEXECUTIONTIME$\t$HOSTOUTPUT$\t$HOSTPERFDATA$"
    "service_perfdata_file_template" : string = "[SERVICEPERFDATA]\t$TIMET$\t$HOSTNAME$\t$SERVICEDESC$\t$SERVICEEXECUTIONTIME$\t$SERVICELATENCY$\t$SERVICEOUTPUT$\t$SERVICEPERFDATA$"
    "host_perfdata_file_mode" : string = "a"
    "service_perfdata_file_mode" : string = "a"
    "host_perfdata_file_processing_interval" : long = 0
    "service_perfdata_file_processing_interval" : long = 0
    "host_perfdata_file_processing_command" ? icinga_commandstrings
    "service_perfdata_file_processing_command" ? icinga_commandstrings
    "allow_empty_hostgroup_assignment" ? boolean
    "obsess_over_services" : boolean = false
    "check_for_orphaned_services" : boolean = true
    "check_service_freshness" : boolean = true
    "service_freshness_check_interval" : long = 60
    "check_host_freshness" : boolean = true
    "host_freshness_check_interval" : long = 60
    "status_update_interval" : long = 30
    "enable_flap_detection" : boolean = true
    "low_service_flap_threshold" : long = 15
    "high_service_flap_threshold" : long = 25
    "low_host_flap_threshold" : long = 5
    "high_host_flap_threshold" : long = 20
    "date_format" : string = "euro"
    "p1_file" ? string = "/usr/bin/p1.pl"
    "enable_embedded_perl" : boolean = false
    "use_embedded_perl_implicitly" : boolean = true
    "stalking_event_handlers_for_hosts" : boolean = false
    "stalking_event_handlers_for_services" : boolean = false
    "illegal_object_name_chars" : string = "`~!$%^&*|'<>?,()\""
    "illegal_macro_output_chars" : string = "`~$^&|'<>\""
    "use_regexp_matching" : boolean = true
    "use_true_regexp_matching" : boolean = false
    "admin_email" : string = "icinga"
    "admin_pager" : string = "pageicinga"
    "daemon_dumps_core" : boolean = false
    # To be used on icinga v3
    "check_result_path" ? string
    "precached_object_file" ? string = "/var/icinga/objects.precache"
    "temp_path" ? string
    "retained_host_attribute_mask" ? boolean
    "retained_service_attribute_mask" ? boolean
    "retained_process_host_attribute_mask" ? boolean
    "retained_process_service_attribute_mask" ? boolean
    "retained_contact_host_attribute_mask" ? boolean
    "retained_contact_service_attribute_mask" ? boolean
    "max_check_result_file_age" ? long
    "translate_passive_host_checks" ? boolean
    "passive_host_checks_are_soft" ? boolean
    "enable_predictive_host_dependency_checks" ? boolean
    "enable_predictive_service_dependency_checks" ? boolean
    "cached_host_check_horizon" ? long
    "cached_service_check_horizon" ? long
    "use_large_installation_tweaks" ? boolean
    "free_child_process_memory" ? boolean
    "child_processes_fork_twice" ? boolean
    "enable_environment_macros" ? boolean
    "soft_state_dependencies" ? boolean
    "ochp_timeout" ? long
    "ochp_command" ? string
    "use_timezone" ? string
    "broker_module" ? string[] with {
            deprecated(0, 'deprecated recent versions of icinga 1.X, use module instead'); true; }
    "module" ? string[]
    "debug_file" ? string
    "debug_level" ? long
    "debug_verbosity" ? long (0..2)
    "max_debug_file_size" ? long
    "ocsp_command" ? string
    "check_result_path" : string = "/var/icinga/checkresults"
    "event_profiling_enabled" ? boolean = false with {deprecated(0, 'removed in recent versions of icinga 1.X'); true; }
    "additional_freshness_latency" ? long
    "check_for_orphaned_hosts" ? boolean
    "check_result_reaper_frequency" ? long
    "keep_unknown_macros" ? boolean
    "max_check_result_reaper_time" ? long
    "obsess_over_hosts" ? boolean
    "service_check_timeout_state" ? string
    "stalking_notifications_for_hosts" ? boolean
    "stalking_notifications_for_services" ? boolean
    "syslog_local_facility" ? long
    "use_daemon_log" ? boolean
    "use_syslog_local_facility" ? boolean
} = dict();

type structure_icinga_service_list = structure_icinga_service[];

type structure_icinga_ido2db_cfg = {
    "lock_file" : string = "/var/icinga/ido2db.lock"
    "ido2db_user" : string = "icinga"
    "ido2db_group" : string = "icinga"
    "socket_type" : string = "unix"
    "socket_name" : string = "/var/icinga/ido.sock"
    "tcp_port" : long = 5668
    "use_ssl" : boolean = false
    "db_servertype" : string = "pgsql"
    "db_host" : string = "localhost"
    "db_port" : long = 5432
    "db_name" : string = "icinga"
    "db_prefix" : string = "icinga_"
    "db_user" : string = "icinga"
    "db_pass" : string = "icinga"
    "max_timedevents_age" : long = 60
    "max_systemcommands_age" : long = 1440
    "max_servicechecks_age" : long = 1440
    "max_hostchecks_age" : long = 1440
    "max_eventhandlers_age" : long = 10080
    "max_externalcommands_age" : long = 10080
    "clean_realtime_tables_on_core_startup" ? boolean = true with {
        deprecated(0, 'removed in recent versions of idoutils 1.13.X');
        true;
    }
    "clean_config_tables_on_core_startup" ? boolean = true with {
        deprecated(0, 'removed in recent versions of idoutils 1.13.X');
        true;
    }
    "trim_db_interval" : long = 3600
    "housekeeping_thread_startup_delay" : long = 300
    "debug_level" : long = 0
    "debug_verbosity" : long = 1
    "debug_file" : string = "/var/icinga/ido2db.debug"
    "max_debug_file_size" : long = 100000000
    "oci_errors_to_syslog" : boolean = true
    "debug_readable_timestamp" ? boolean
    "max_acknowledgements_age" ? long
    "max_contactnotificationmethods_age" ? long
    "max_contactnotifications_age" ? long
    "max_logentries_age" ? long
    "max_notifications_age" ? long
    "socket_perm" ? string
} = dict();

# Everything that can be handled by this component
type structure_component_icinga = {
    include structure_component
    "ignore_hosts" ? string[]
    "hosts" : structure_icinga_host {}
    "hosts_generic" ? structure_icinga_host_generic {}
    "hostgroups" ? structure_icinga_hostgroup {}
    "hostdependencies" ? structure_icinga_hostdependency {}
    "services" : structure_icinga_service_list {} with icinga_check_service_name(SELF)
    "servicegroups" ? structure_icinga_servicegroup {}
    "general" : structure_icinga_icinga_cfg
    "cgi" : structure_icinga_cgi_cfg
    "serviceextinfo" ? structure_icinga_serviceextinfo []
    "servicedependencies" ? structure_icinga_servicedependency []
    "timeperiods" : structure_icinga_timeperiod {}
    "contacts" : structure_icinga_contact {}
    "contactgroups" : structure_icinga_contactgroup {}
    "commands" : string {}
    "macros" ? string {}
    "external_files" ? string[]
    "external_dirs" ? string[]
    "ido2db" : structure_icinga_ido2db_cfg
    # Service escalations and dependencies are left for later
    # versions.
};
