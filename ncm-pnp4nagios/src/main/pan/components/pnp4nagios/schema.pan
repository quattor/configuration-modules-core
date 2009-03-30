# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/pnp4nagios/schema;

include {'quattor/schema'};

# Convenience type definitions

type viewskey = long with exists ("/software/components/pnp4nagios/php/views/" + to_string(SELF)) ||
                               error ("No views with key " + to_string(SELF));
 

# Npcd configuration options
type structure_pnp4nagios_npcd = {
	"user" : string = "nagios"
	"group" : string = "nagios"
	"log_type" : string with match (SELF, "syslog|file")
	"log_file" : string = "/var/log/pnp4nagios//perfdata.log" # path to your logfile
	"max_logfile_size" : long = 10485760 # maximum filesize (bytes) before the logfile will rotated.
	"log_level" : string with match (SELF, "0|1|2|-1")
	"perfdata_spool_dir" : string = "/var/log/nagios/spool/perfdata"
	"perfdata_file_run_cmd" : string = "/usr/libexec/pnp4nagios/process_perfdata.pl"
	"perfdata_file_run_cmd_args" : string = "-b"
	"npcd_max_threads" : long = 5 # how many parallel threads we should start
	"sleep_time" : long = 15 # how many seconds should npcd wait between dirscans
	"use_load_threshold" : string with match (SELF,"0|1")
	"load_threshold" : double = 10.0
	"pid_file" : string = "/var/run/npcd.pid"
};

# Php configuration options conf
type structure_pnp4nagios_php_conf = {
	"rrdtool" : string = "/usr/bin/rrdtool" # Path to rrdtool
	"graph_width" : long = 500
	"graph_height" : long = 100
	"graph_opt" : string = "" # Additional Options for RRDTool
	"rrdbase" :string = "/var/lib/pnp4nagios/"# Directory where the RRD Files will be stored
	"page_dir" : string = "/etc/pnp4nagios//pages/" # Page Config Location
	"refresh" : long = 90 # Site Refresh Time in Secounds
	"max_age" : long = (60*60*60) # Max Age for RRD Files in Secounds
	"temp" : string = "/var/tmp" # Directory for Temporary Files used for PDF creation
	"nagios_base" : string = "/nagios/cgi-bin"
	"allowed_for_service_links": string = "EVERYONE" # Which User is allowed to see additional Service Links
	"allowed_for_host_search" : string = "EVERYONE" # Who can use the Host Search Funktion
	"allowed_for_host_overview" : string = "EVERYONE" # Who can use the Host Overview
	"allowed_for_pages" :string = "EVERYONE" # Who can use the Pages function
	"overview-range" : viewskey = 0 # Key from array views ??? 
	"lang" : string with match (SELF,"de|en|nl|se|fr")
	"date_fmt" : string = "d.m.y G:i"
	"use_fpdf" : long(0..1) = 1 # Use FPDF Lib for PDF Creation
	"background_pdf" : string = "/etc/pnp4nagios//background.pdf" # Use this file as PDF Background
	"use_calendar" : long(0..1) = 1 # Enable JSCalendar
};

# Php configuration options view
type structure_pnp4nagios_php_view = {
	"index" : long
	"title" : string
	"start" : long # Start timerange in seconds
};


# Php configuration options
type structure_pnp4nagios_php = {
	"conf" : structure_pnp4nagios_php_conf
	"views" : structure_pnp4nagios_php_view[]
};

# Page configuration options
type structure_pnp4nagios_page_cfg = {
	"page_name" : string
	"use_regex" : string with match (SELF,"0|1")
};

# Graph configuration options
type structure_pnp4nagios_page_graph = {
	"host_name" : string
	"service_desc" : string
};

# Page options
type structure_pnp4nagios_page = {
	"page_cfg" : structure_pnp4nagios_page_cfg
	"graphs" : structure_pnp4nagios_page_graph[]
};

# Template configuration options def
type structure_pnp4nagios_template_def = {
	"def" : string
	"cond" ? string
};

# Template configuration options dataset
type structure_pnp4nagios_template_dataset = {
	"index" : long
	"opt" : string
	"defs" : structure_pnp4nagios_template_def[]
};

# Template options
type structure_pnp4nagios_template = {
	"datasets" : structure_pnp4nagios_template_dataset[]
};

# The full definition for the component
type structure_component_pnp4nagios = {
	include structure_component
	"npcd" : structure_pnp4nagios_npcd
	"php" : structure_pnp4nagios_php
	"pages" ? structure_pnp4nagios_page{}
	"templates" ? structure_pnp4nagios_template{}
};

bind "/software/components/pnp4nagios" = structure_component_pnp4nagios;