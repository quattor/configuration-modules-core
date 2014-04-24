# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/${project.artifactId}/schema;

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
	"profile_format" : string = "xml"
        "osinstalldir"  ? string
        "nbpdir"        ? string
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
