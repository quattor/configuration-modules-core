# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/pnp4nagios/schema;

include 'quattor/schema';

type pnp4nagios_php_view_type = {
    'title' : string
    'start' : long
};

type pnp4nagios_npcd_log_type = string with match(SELF, "file|syslog");
type pnp4nagios_php_paper_size = string with match(SELF, "A4|Letter");
type pnp4nagios_php_ui_theme = string with match(SELF, "smoothness|lightness|redmond|multisite");
type pnp4nagios_php_lang = string with match(SELF, "en_US|de_DE|es_ES|ru_RU|fr_FR");
type pnp4nagios_perfdata_RRD_storage_type = string with match(SELF, "SINGLE|MULTIPLE");

type pnp4nagios_npcd_config = {
    "user" : string    = 'nagios'
    "group" : string    = 'nagios'
    "log_type" : pnp4nagios_npcd_log_type  = 'syslog'
    "log_file" : string    = '/var/log/pnp4nagios/npcd.log'
    "max_logfile_size" : long      = 10485760
    "log_level" : long(0..2) = 0
    "perfdata_spool_dir" : string    = '/var/spool/pnp4nagios/'
    "perfdata_file_run_cmd" : string    = '/usr/libexec/pnp4nagios/process_perfdata.pl'
    "perfdata_file_run_cmd_args" : string    = '-b'
    "identify_npcd" : boolean   = true
    "npcd_max_threads" : long      = 5
    "sleep_time" : long      = 15
    "load_threshold" : double    = 0.0
    "pid_file" : string    = '/var/run/npcd.pid'
    "perfdata_file" : string    = '/var/log/pnp4nagios/perfdata.dump'
    "perfdata_spool_filename" : string    = 'perfdata'
    "perfdata_file_processing_interval" : long      = 15
};

type pnp4nagios_php_config = {
    'use_url_rewriting' : boolean = true
    'rrdtool' : string = "/usr/bin/rrdtool"
    'graph_width' : long = 500
    'graph_height' : long   = 100
    'zgraph_width' : long = 500
    'zgraph_height' : long = 100
    'right_zoom_offset' : long = 30
    'pdf_width' : long = 675
    'pdf_height' : long = 100
    'pdf_page_size' : pnp4nagios_php_paper_size = "A4"
    'pdf_margin_top' : long = 30
    'pdf_margin_left' : double = 17.5
    'pdf_margin_right' : long = 10
    'graph_opt' : string = ''
    'pdf_graph_opt' : string = ''
    'rrdbase' : string = '/var/lib/pnp4nagios/'
    'page_dir' : string = '/etc/pnp4nagios/pages/'
    'refresh' : long = 90
    'max_age' : long = 21600
    'temp' : string = '/var/tmp'
    'nagios_base' : string = '/nagios/cgi-bin'
    'multisite_base_url' : string = '/check_mk'
    'multisite_site' : string = ''
    'auth_enabled' : boolean = false
    'livestatus_socket' : string = 'unix:/usr/local/nagios/var/rw/live'
    'allowed_for_all_services' : string = ''
    'allowed_for_all_hosts' : string = ''
    'allowed_for_service_links' : string = 'EVERYONE'
    'allowed_for_host_search' : string = 'EVERYONE'
    'allowed_for_host_overview' : string = 'EVERYONE'
    'allowed_for_pages' : string = 'EVERYONE'
    'overview-range' : long   = 1
    'popup-width' : string = '300px'
    'ui-theme' : pnp4nagios_php_ui_theme = 'smoothness'
    'lang' : pnp4nagios_php_lang = 'en_US'
    'date_fmt' : string = 'd.m.y G:i'
    'enable_recursive_template_search' : boolean = true
    'show_xml_icon' : boolean = true
    'use_fpdf' : boolean = true
    'background_pdf' : string = '/etc/pnp4nagios/background.pdf'
    'use_calendar' : boolean = true
    'views' : pnp4nagios_php_view_type[] = list(dict('title', 'Four_Hours', 'start', 14400), dict('title', 'Twentyfive_Hours', 'start', 90000), dict('title', 'One_Week', 'start', 630000), dict('title', 'One_Month', 'start', 2764800), dict('title', 'One_Year', 'start', 32832000))
    'rrd_daemon_opts' : string = ''
    'template_dirs' : string[] = list('/usr/share/icinga/html/pnp4nagios/templates', '/usr/share/icinga/html/pnp4nagios/templates.dist')
    'special_template_dir' : string = '/usr/share/icinga/html/pnp4nagios/templates.special'
    'mobile_devices' : string = 'iPhone|iPod|iPad|android'
};

type pnp4nagios_nagios_config = {
    'process_performance_data' : boolean   = true
    'service_perfdata_command' : string    = 'process-service-perfdata'
    'process_performance_data' : boolean   = true
    'service_perfdata_file' : string    = '/var/log/pnp4nagios/service-perfdata'
    'service_perfdata_file_template' : string    = 'DATATYPE::SERVICEPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tSERVICEDESC::$SERVICEDESC$\tSERVICEPERFDATA::$SERVICEPERFDATA$\tSERVICECHECKCOMMAND::$SERVICECHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$\tSERVICESTATE::$SERVICESTATE$\tSERVICESTATETYPE::$SERVICESTATETYPE$'
    'service_perfdata_file_mode' : string    = 'a'
    'service_perfdata_file_processing_interval' : long      = 15
    'service_perfdata_file_processing_command' : string    = 'process-service-perfdata-file'
    'host_perfdata_file' : string    = '/var/log/pnp4nagios//host-perfdata'
    'host_perfdata_file_template' : string    = 'DATATYPE::HOSTPERFDATA\tTIMET::$TIMET$\tHOSTNAME::$HOSTNAME$\tHOSTPERFDATA::$HOSTPERFDATA$\tHOSTCHECKCOMMAND::$HOSTCHECKCOMMAND$\tHOSTSTATE::$HOSTSTATE$\tHOSTSTATETYPE::$HOSTSTATETYPE$'
    'host_perfdata_file_mode' : string    = 'a'
    'host_perfdata_file_processing_interval' : long      = 15
    'host_perfdata_file_processing_command' : string    = 'process-host-perfdata-file'
    'process_performance_data' : boolean   = true
    'broker_module' : string[]  =list("/usr/lib64/npcdmod.o", "config_file=/etc/pnp4nagios/npcd.cfg")
};

type pnp4nagios_perfdata_config = {
    'timeout' : long      = 15
    'use_rrds' : boolean   = true
    'rrdpath' : string    = '/var/lib/pnp4nagios/'
    'rrdtool' : string    = '/usr/bin/rrdtool'
    'cfg_dir' : string    = '/etc/pnp4nagios/'
    'rrd_storage_type' : pnp4nagios_perfdata_RRD_storage_type = 'SINGLE'
    'rrd_heartbeat' : long      = 8460
    'rra_cfg' : string    = '/etc/pnp4nagios/rra.cfg'
    'rra_step' : long      = 60
    'log_file' : string    = '/var/log/pnp4nagios/perfdata.log'
    'log_level' : long(0..2) = 0
    'xml_enc' : string    = 'UTF-8'
    'xml_update_delay' : long      = 0
    'rrd_daemon_opts' ? string    # unix:/tmp/rrdcached.sock
    'stats_dir' : string    = '/var/log/pnp4nagios/stats'
    'prefork' : boolean   = true
    'gearman_host' : string    = 'localhost:4730'
    'requests_per_child' : long      = 10000
    'encryption' : boolean   = true
    'key' : string    = 'should_be_changed'
    'key_file' ? string    # /etc/pnp4nagios/secret.key
};


# The full definition for the component
type structure_component_pnp4nagios = {
    include structure_component
    "npcd" : pnp4nagios_npcd_config
    "php" : pnp4nagios_php_config
    "perfdata" : pnp4nagios_perfdata_config
    "nagios" : pnp4nagios_nagios_config
};

bind "/software/components/pnp4nagios" = structure_component_pnp4nagios;