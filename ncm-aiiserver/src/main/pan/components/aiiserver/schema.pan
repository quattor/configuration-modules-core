# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/aiiserver/schema;

include {'quattor/schema'};

type structure_aiishellfe = {
	"cdburl"	: type_absoluteURI
	"nodhcp"	? boolean
	"nonbp"		? boolean
	"noosinstall"	? boolean
	"logfile"	? string
	"profile_prefix" ? string
	"noaction"	? boolean
	"use_fqdn"	: boolean = true
	"ca_file"	? string
	"key_file"	? string
	"cert_file"	? string
};

type structure_aiidhcp = {
    "dhcpconf"		: string = "/etc/dhcpd.conf"
    "restartcmd"	? string
    "norestart"		? boolean
};

type structure_component_aiiserver = {
	include structure_component
	"aii-shellfe"	: structure_aiishellfe
	"aii-dhcp"      : structure_aiidhcp
};

bind "/software/components/aiiserver" = structure_component_aiiserver;
