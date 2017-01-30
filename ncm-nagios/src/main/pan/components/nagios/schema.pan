# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/nagios/schema;

include 'quattor/types/component';
include 'pan/types';

# Please note that the "use" directive is not supported in order to make
# validation code easier. If you want hosts to inherit settings then use
# Pan statements like create ("...") or value ("...")

type nagios_hoststring =  string with exists ("/software/components/nagios/hosts/" + SELF) ||
    SELF=="*";

type nagios_hostgroupstring = string with exists ("/software/components/nagios/hostgroups/" + SELF) || SELF=="*";

type nagios_commandstrings = string [] with exists ("/software/components/nagios/commands/" + SELF[0]);

type nagios_timeperiodstring = string with exists ("/software/components/nagios/timeperiods/" + SELF) ||
    SELF=="*";

type nagios_contactgroupstring = string with exists ("/software/components/nagios/contactgroups/" + SELF) ||
    SELF=="*";

type nagios_contactstring = string with exists ("/software/components/nagios/contacts/" + SELF) ||
    SELF=="*";

type nagios_servicegroupstring = string with exists ("/software/components/nagios/servicegroups/" + SELF) ||
    SELF=="*";

type nagios_servicestring = string with exists ("/software/components/nagios/services/" + SELF) ||
    SELF=="*";

type nagios_service_notification_string = string with match (SELF, "^(w|u|c|r|f)$");
type nagios_host_notification_string = string with match (SELF, "^(d|u|r|f)$");
type nagios_stalking_string = string with match (SELF, "^(o|w|u|c)$");
type nagios_execution_failure_string = string with match (SELF, "^(o|w|u|c|p|n)$");
type nagios_notification_failure_string = string with match (SELF, "^(o|w|u|c|p|n)$");

type structure_nagios_host_generic = {
    "name" ? string # Used instead of alias when it s a template declaration
    "check_command" : nagios_commandstrings
    "max_check_attempts" : long
    "check_interval" ? long
    "retry_interval" ? long
    "active_checks_enabled" ? boolean
    "passive_checks_enabled" ? boolean
    "check_period" : nagios_timeperiodstring
    "obsess_over_host" ? boolean
    "check_freshness" ? boolean
    "freshness_threshold" ? long
    "event_handler" ? nagios_commandstrings
    "event_handler_enabled" ? boolean
    "low_flap_threshold" ? long
    "high_flap_threshold" ? long
    "flap_detection_enabled" : boolean = true
    "process_perf_data" ? boolean
    "retain_status_information" ? boolean
    "retain_nonstatus_information" ? boolean
    "contact_groups" : nagios_contactgroupstring[]
    "notification_interval" : long
    "notification_period" : nagios_timeperiodstring
    "notification_options" : nagios_host_notification_string []
    "notifications_enabled" ? boolean
    "stalking_options" ? string with match (SELF, "^(o|d|u)$")
    "register" : boolean = true
};

# Host definition.
type structure_nagios_host = {
    "alias" : string
    "use" ? string # Used to insert a template host declaration
    "address" ? type_ip # If not present, gethostbyname will be used.
    "parents" ? nagios_hoststring[]
    "hostgroups" ? nagios_hostgroupstring[]
    "check_command" : nagios_commandstrings
    "max_check_attempts" : long
    "check_interval" ? long
    "active_checks_enabled" ? boolean
    "passive_checks_enabled" ? boolean
    "check_period" : nagios_timeperiodstring
    "obsess_over_host" ? boolean
    "check_freshness" ? boolean
    "freshness_threshold" ? long
    "event_handler" ? nagios_commandstrings
    "event_handler_enabled" ? boolean
    "low_flap_threshold" ? long
    "high_flap_threshold" ? long
    "flap_detection_enabled" : boolean = true
    "process_perf_data" ? boolean
    "retain_status_information" ? boolean
    "retain_nonstatus_information" ? boolean
    "contact_groups" : nagios_contactgroupstring[]
    "notification_interval" : long
    "notification_period" : nagios_timeperiodstring
    "notification_options" : nagios_host_notification_string []
    "notifications_enabled" ? boolean
    "stalking_options" ? string with match (SELF, "^(o|d|u)$")
    "register" : boolean = true
    "action_url" ? string
};

# Hostgroup definition
type structure_nagios_hostgroup = {
    "alias" : string
    "members" ? nagios_hoststring[]
};

# Host dependency definition
type structure_nagios_hostdependency = {
    "dependent_host_name" : nagios_hoststring # Should be string[]?
    "notification_failure_criteria" : nagios_host_notification_string[]
};

# Service definition
type structure_nagios_service = {
    "name" ? string # Used when it s a template declaration
    "use" ? string # Used to include template
    "host_name" ? nagios_hoststring[]
    "hostgroup_name" ? nagios_hostgroupstring[]
    "servicegroups" ? nagios_servicegroupstring []
    "is_volatile" ? boolean
    "check_command" ? nagios_commandstrings
    "max_check_attempts" : long
    "normal_check_interval" : long
    "retry_check_interval" : long
    "active_checks_enabled" ? boolean
    "passive_checks_enabled" ? boolean
    "check_period" ? nagios_timeperiodstring
    "parallelize_check" ? boolean # deprecated in Nagios 3
    "obsess_over_service" ? boolean
    "check_freshness" ? boolean
    "freshness_threshold" ? long
    "event_handler" ? nagios_commandstrings
    "event_handler_enabled" ? boolean
    "low_flap_threshold" ? long
    "high_flap_threshold" ? long
    "flap_detection_enabled" : boolean = true
    "process_perf_data" ? boolean
    "retain_status_information" ? boolean
    "retain_nonstatus_information" ? boolean
    "notification_interval" : long
    "notification_period" : nagios_timeperiodstring
    "notification_options" : nagios_service_notification_string []
    "notifications_enabled" ? boolean
    "contact_groups" : nagios_contactgroupstring[]
    "stalking_options" ? nagios_stalking_string[]
    "register" : boolean = true
    "failure_prediction_enabled" ? boolean
    "action_url" ? string
} with nagios_has_host_or_hostgroup (SELF);;

# Servicegroup definition:
type structure_nagios_servicegroup = {
    "alias" : string
    "members" ? nagios_servicestring []
    "servicegroup_members" ? nagios_servicegroupstring[]
    "notes" ? string
    "notes_url" ? type_absoluteURI
    "action_url" ? type_absoluteURI
};

# Servicedependency definition:
type structure_nagios_servicedependency = {
    "dependent_host_name" : nagios_hoststring[]
    "dependent_hostgroup_name" ? nagios_hostgroupstring[]
    "dependent_service_description" : nagios_servicestring
    "host_name" ? nagios_hoststring
    "hostgroup_name" ? nagios_hostgroupstring
    "service_description" : string
    "inherits_parent" ? boolean
    "execution_failure_criteria" ? nagios_execution_failure_string []
    "notification_failure_criteria" ? nagios_notification_failure_string []
    "dependency_period" ? nagios_timeperiodstring
} with nagios_has_host_or_hostgroup (SELF);;

# Contact definition
type structure_nagios_contact = {
    "alias" : string
    "contactgroups" : nagios_contactgroupstring []
    "host_notification_period" : nagios_timeperiodstring
    "service_notification_period" : nagios_timeperiodstring
    "host_notification_options" : nagios_host_notification_string []
    "service_notification_options" : nagios_service_notification_string []
    "host_notification_commands" : nagios_commandstrings []
    "service_notification_commands" : nagios_commandstrings []
    "email" : string
    "pager" : string
};

# Contact group definition
type structure_nagios_contactgroup = {
    "alias" : string
    "members" : nagios_contactstring[]
};

# Time range definition
type nagios_timerange = string with
    match (SELF, "^(([0-9]+:[0-9]+)-([0-9]+:[0-9]+),)*([0-9]+:[0-9]+)-([0-9]+:[0-9]+)$");

# Time period definition
type structure_nagios_timeperiod = {
    "alias" ? string
    "monday" ? nagios_timerange
    "tuesday" ? nagios_timerange
    "wednesday" ? nagios_timerange
    "thursday" ? nagios_timerange
    "friday" ? nagios_timerange
    "saturday" ? nagios_timerange
    "sunday" ? nagios_timerange
};

# Extended information for services
# Deprecated in Nagios 3
type structure_nagios_serviceextinfo = {
    "host_name" ? nagios_hoststring[]
    "service_description" : string
    "hostgroup_name" ? nagios_hostgroupstring[]
    "notes" ? string
    "notes_url" ? type_absoluteURI
    "action_url" ? type_absoluteURI
    "icon_image" ? string
    "icon_image_alt" ? string
} with nagios_has_host_or_hostgroup (SELF);

# CGI configuration
type structure_nagios_cgi_cfg = {
    "physical_html_path" : string = "/usr/share/nagios"
    "url_html_path" : string = "/nagios"
    "show_context_help" : boolean = false
    "nagios_check_command" ? string
    "use_authentication" : boolean = true
    "default_user_name" ? string
    "authorized_for_system_information" ? string
    "authorized_for_configuration_information" ? string
    "authorized_for_system_commands" ? string
    "authorized_for_all_services" ? string
    "authorized_for_all_hosts" ? string
    "authorized_for_all_service_commands" ? string
    "authorized_for_all_host_commands" ? string
    "statusmap_background_image" ? string
    "default_statusmap_layout" : long = 5
    "default_statuswrl_layout" : long = 4
    "statuswrl_include" ? string
    "ping_syntax" : string = "/bin/ping -n -U -c 5 $HOSTADDRESS$"
    "refresh_rate" : long = 90
    "host_unreachable_sound" ? string
    "host_down_sound" ? string
    "service_critical_sound" ? string
    "service_warning_sound" ? string
    "service_unknown_sound" ? string
    "normal_sound" ? string
};

# General options
type structure_nagios_nagios_cfg = {
    "log_file" : string = "/var/log/nagios/nagios.log"
    "object_cache_file" : string = "/var/log/nagios/objects.cache"
    "resource_file" : string = "/etc/nagios/resource.cfg"
    "status_file" : string = "/var/log/nagios/status.dat"
    "nagios_user" : string = "nagios"
    "nagios_group" : string = "nagios"
    "check_external_commands" : boolean = false
    "command_check_interval" : long = -1
    "command_file" : string = "/var/log/nagios/rw/nagios.cmd"
    "external_command_buffer_slots" : long = 4096
    "comment_file" : string = "/var/log/nagios/comments.dat" # deprecated in Nagios 3
    "downtime_file" : string = "/var/log/nagios/downtime.dat" # deprecated in Nagios 3
    "lock_file" : string = "/var/run/nagios.pid"
    "temp_file" : string = "/var/log/nagios/nagios.tmp"
    "event_broker_options" : long = -1
    "log_rotation_method" : string = "d"
    "log_archive_path" : string = "/var/log/nagios/archives"
    "use_syslog" : boolean = true
    "log_notifications" : boolean = true
    "log_service_retries" : boolean = true
    "log_host_retries" : boolean = true
    "log_event_handlers" : boolean = true
    "log_initial_states" : boolean = false
    "log_external_commands" : boolean = true
    "log_passive_checks" : boolean = true
    "global_host_event_handler" ? string
    "service_inter_check_delay_method" : string = "s"
    "max_service_check_spread" : long = 30
    "service_interleave_factor" : string = "s"
    "host_inter_check_delay_method" : string = "s"
    "max_host_check_spread" : long = 30
    "max_concurrent_checks" : long = 0
    "service_reaper_frequency" : long = 10 # deprecated in Nagios 3
    "check_result_reaper_frequency" ? long # replaces check_result_reaper_frequency
    "max_check_result_reaper_time" ? long
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
    "state_retention_file" : string = "/var/log/nagios/retention.dat"
    "retention_update_interval" : long = 60
    "use_retained_program_state" : boolean = true
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
    "service_perfdata_command" : nagios_commandstrings = list("process-service-perfdata")
    "host_perfdata_command" : nagios_commandstrings = list("process-host-perfdata")
    "host_perfdata_file" : string = "/var/log/nagios/host-perf.dat"
    "service_perfdata_file" : string = "/var/log/nagios/service-perf.dat"
    "host_perfdata_file_template" : string = "[HOSTPERFDATA]\t$TIMET$\t$HOSTNAME$\t$HOSTEXECUTIONTIME$\t$HOSTOUTPUT$\t$HOSTPERFDATA$"
    "service_perfdata_file_template" : string = "[SERVICEPERFDATA]\t$TIMET$\t$HOSTNAME$\t$SERVICEDESC$\t$SERVICEEXECUTIONTIME$\t$SERVICELATENCY$\t$SERVICEOUTPUT$\t$SERVICEPERFDATA$"
    "host_perfdata_file_mode" : string = "a"
    "service_perfdata_file_mode" : string = "a"
    "host_perfdata_file_processing_interval" : long = 0
    "service_perfdata_file_processing_interval" : long = 0
    "host_perfdata_file_processing_command" ? nagios_commandstrings
    "service_perfdata_file_processing_command" ? nagios_commandstrings
    "obsess_over_services" : boolean = false
    "check_for_orphaned_services" : boolean = true
    "check_service_freshness" : boolean = true
    "service_freshness_check_interval" : long = 60
    "check_host_freshness" : boolean = true
    "host_freshness_check_interval" : long = 60
    "aggregate_status_updates" : boolean = true # deprecated in Nagios 3
    "status_update_interval" : long = 30
    "enable_flap_detection" : boolean = true
    "low_service_flap_threshold" : long = 15
    "high_service_flap_threshold" : long = 25
    "low_host_flap_threshold" : long = 5
    "high_host_flap_threshold" : long = 20
    "date_format" : string = "euro"
    "p1_file" : string = "/usr/bin/p1.pl"
    "illegal_object_name_chars" : string = "`~!$%^&*|'<>?,()\""
    "illegal_macro_output_chars" : string = "`~$^&|'<>\""
    "use_regexp_matching" : boolean = true
    "use_true_regexp_matching" : boolean = false
    "admin_email" : string = "nagios"
    "admin_pager" : string = "pagenagios"
    "daemon_dumps_core" : boolean = false
    # To be used on Nagios v3
    "check_result_path" ? string
    "precached_object_file" ? string
    "temp_path" ? string
    "retained_host_attribute_mask" ? long
    "retained_service_attribute_mask" ? long
    "retained_process_host_attribute_mask" ? long
    "retained_process_service_attribute_mask" ? long
    "retained_contact_host_attribute_mask" ? long
    "retained_contact_service_attribute_mask" ? long
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
    "broker_module" ? string[]
    "debug_file" ? string
    "debug_level" ? long
    "debug_verbosity" ? long (0..2)
    "max_debug_file_size" ? long
    "ocsp_command" ? string
};

type structure_nagios_service_list=structure_nagios_service[];

# Everything that can be handled by this component
type structure_component_nagios = {
    include structure_component
    "hosts" : structure_nagios_host {}
    "hosts_generic" ? structure_nagios_host_generic {}
    "hostgroups" ? structure_nagios_hostgroup {}
    "hostdependencies" ? structure_nagios_hostdependency {}
    "services" : structure_nagios_service_list {}
    "servicegroups" ? structure_nagios_servicegroup {}
    "general" : structure_nagios_nagios_cfg
    "cgi" ? structure_nagios_cgi_cfg
    "serviceextinfo" ? structure_nagios_serviceextinfo []
    "servicedependencies" ? structure_nagios_servicedependency []
    "timeperiods" : structure_nagios_timeperiod {}
    "contacts" : structure_nagios_contact {}
    "contactgroups" : structure_nagios_contactgroup {}
    "commands" : string {}
    "macros" ? string {}
    "external_files" ? string[]
    "external_dirs" ? string[]
    # Service escalations and dependencies are left for later
    # versions.
};

bind "/software/components/nagios" = structure_component_nagios;
