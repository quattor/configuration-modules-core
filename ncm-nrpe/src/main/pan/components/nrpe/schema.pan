# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/nrpe/schema;

include {'quattor/schema'};

type structure_component_nrpe = {
	include structure_component
	"add_rc"	: boolean # Whether to chkconf the NRPE service.
	"cmds"		: string{} # Indexed by command name.
	"user"		: string = "nagios" # User owning the process
	"group"		: string = "nagios" # Group owning the process
	"allowed_hosts"	: type_hostname[]
	"allow_cmdargs"	: boolean = false
	"prefix"	? string
	"timeout"	: long
	"weak_random"	: boolean # Usually you want this to be false.
	"port"		: long
    "external_files" ? string[]
};

bind "/software/components/nrpe" = structure_component_nrpe;
