# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/networkupstools/schema;

include {'quattor/schema'};

type action_string = string with match (SELF, '^(SET|FSD)$');

type ups_device_string = string with is_hostname (SELF) ||
    match (SELF, '^/dev/ttyS[0-9]+$') ||
    SELF == 'auto';

type string_upsmonact = string with match (SELF,
    "^(SYSLOG|WALL|EXEC|IGNORE)$");

type eventstring = string with match (SELF,
    "^(online|onbatt|lowbatt|fsd|commok|commbad|shutdown|replbatt|nocomm)$");

# Some minimal SNMP settings
type structure_networkupstools_snmp = {
    "mibs"	: string = "auto"
    "community"	? string
    "pollfreq"	? long
};

# UPS internal settings to be sent with upscmd
type structure_networkupstools_upssettings = {
    "setting"	: string with match (SELF, '^\w+=\w+$')
    "user"	: string
    "password"	: string
};

# UPS definition
type structure_ups = {
    "driver"	: string
    "port"	: ups_device_string
    "description"	: string
    "cable"	? string
    "sdorder"	? long
    "lock"	? boolean
    # This is for APC UPSs, using the apcsmart driver.
    "shutdown"	? long (0..4)
    # Additional settings to be set with upscmd -s
    "upsconfig"	? structure_networkupstools_upssettings[]
    "snmpcfg"	? structure_networkupstools_snmp
};

type structure_networkupstools_ups = structure_ups with
    (!exists (SELF["snmpcfg"]) && SELF["driver"] != "snmp-ups") ||
    (exists (SELF["snmpcfg"]) && SELF["driver"] == "snmp-ups");

# upsd user definition
type structure_networkupstools_user = {
    "password"	: string
    "allowfrom"	: type_hostname
    "actions"	: action_string[1..2]
    "instcmds"	: string[]
    "upsmon"	? string with match (SELF, '^(master|slave)$')
};

# ACL definition
type structure_networkupstools_acls = {
    "network"	: type_network_name
    "accept"	: boolean
};

type structure_networkupstools_address = {
    "ip"	: type_ip
    "port"	: long (1..65535)
};

# UPS daemon configuration
type structure_networkupstools_upsd = {
	# Where to listen from
	"acls"	: structure_networkupstools_acls{}
	"maxage"? long
	"listen"? structure_networkupstools_address
};

# UPS monitoring statement
type structure_networkupstools_upsmon_monitor = {
    "ups"	: string with match (SELF, '.*@.*')
    "power"	: long
    "user"	: string
    "password"	: string
    "type"	: string with match (SELF, '^(master|slave)$')
};

type structure_networkupstools_upsmon_message = {
    "online"	? string
    "onbatt"	? string
    "lowbatt"	? string
    "fsd"	? string
    "commok"	? string
    "commbad"	? string
    "shutdown"	? string
    "replbatt"	? string
    "nocomm"	? string
};

type structure_networkupstools_upsmon_action = {
    "online"	? string_upsmonact[]
    "onbatt"	? string_upsmonact[]
    "lowbatt"	? string_upsmonact[]
    "fsd"	? string_upsmonact[]
    "commok"	? string_upsmonact[]
    "commbad"	? string_upsmonact[]
    "shutdown"	? string_upsmonact[]
    "replbatt"	? string_upsmonact[]
    "nocomm"	? string_upsmonact[]
};


# UPS monitoring definitions
type structure_networkupstools_upsmon = {
    "user"	: string = "nut"
    "monitor"	: structure_networkupstools_upsmon_monitor[]
    "rbwarn"	: long = 43200
    "nocommwarn": long = 300
    "finaldelay": long = 5
    "supplies"	: long = 1
    "shutdown"	: string = "/sbin/shutdown -h now"
    "notifycommand" ? string
    "pollfreq"	: long = 5
    "pollalert": long = 5
    "hostsync"	: long = 15
    "deadtime"	: long = 15
    "powerdownflag" : string = "/etc/killpower"
    "notifymsgs" ? structure_networkupstools_upsmon_message
    "notifyflags": structure_networkupstools_upsmon_action
};

# UPS event handlers
type structure_networkupstools_eventhandler = {
    "condition"	: eventstring
    "ups"	: string
    "action"	: string with match (SELF,
				     '^(START-TIMER|CANCEL-TIMER|EXECUTE)$')
    "timername"	? string
    "actionarguments" ? string
};
    

# UPS event handler scheduler (upssched)
type  structure_networkupstools_upssched = {
    "cmdscript"	: string
    "pipe"	: string
    "lock"	: string
    "handlers"	: structure_networkupstools_eventhandler[]
};

# Component definition
type structure_component_networkupstools = {
	include structure_component
	# UPS definitions, indexed by UPS name
	"upss"	: structure_networkupstools_ups{}
	# Users definitions, indexed by user name
	"users"	: structure_networkupstools_user{}
	# UPSD definitions
	"upsd"	: structure_networkupstools_upsd
	"upsmon": structure_networkupstools_upsmon
	# Event handler definitions
	"upssched" ? structure_networkupstools_upssched
};

bind "/software/components/networkupstools" = structure_component_networkupstools;
