# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/schema;

include 'quattor/schema';
include 'components/spma/functions';
include 'components/spma/ips/schema';
include 'components/spma/yum/schema';

############################################################
#
# SOFTWARE: Type definitions
#
############################################################

type SOFTWARE_PACKAGE_REP = string with repository_exists(SELF,"/software/repositories");

type SOFTWARE_PACKAGE = {
    "arch" ? string{} # architectures
};

type SOFTWARE_REPOSITORY_PACKAGE = {
    "arch" : string  # "Package architecture"
    "name" : string  # "Package name"
    "version" : string  # "Package version"
};

type SOFTWARE_REPOSITORY_PROTOCOL = {
    "name" : string  # "Protocol name"
    "url" : string  # "URL for the given protocol"
    "cacert" ? string  # Path to CA certificate
    "clientcert" ? string # Path to client certificate
    "clientkey" ? string # Path to client key
    "verify" ? boolean # Whether to verify the SSL certificate
};

type SOFTWARE_REPOSITORY = {
    "enabled" : boolean = true
    "gpgcheck" : boolean = false
    "excludepkgs" ? string[]
    "includepkgs" ? string[]
    "name" ? string  # "Repository name"
    "owner" ? string  # "Contact person (email)"
    "priority" ? long(1..99)
    "protocols" ? SOFTWARE_REPOSITORY_PROTOCOL []
    "proxy" ? string with SELF == '' || is_absoluteURI(SELF)
    "skip_if_unavailable" : boolean = false
};

type SOFTWARE_GROUP = {
    "default" : boolean = true
    "mandatory" : boolean = true
    "optional" : boolean = false
};

type boolean_yes_no = string with match (SELF, '^(yes|no)$'); 

type component_spma_type = {
    include structure_component
    include component_spma_ips
    include component_spma_yum
    "cmdfile"       : string = "/var/tmp/spma-commands" # where to save commands for spma-run script
    "packager"      : string = "yum" with match (SELF, '^(yum|ips)$') # system packager to be used (yum,ips)
    "pkgpaths"      : string[] = list("/software/packages") # where to find package definitions
    "process_obsoletes" : boolean = false
    "cachedir"      ? string # SPMA cache directory
    "debug"         ? string with match (SELF, '^(0|1|2|3|4|5)$') # debug level (0-5)
    "flagfile"      ? string # touch this file if there is work to do (i.e. spma-run --execute)
    "headnode"      ? boolean # use head node
    "localcache"    ? boolean_yes_no # Use SPMA package cache
    "protectkernel" ? boolean_yes_no # Prevent currrent kernel from being removed
    "proxy"         ? boolean_yes_no # Enable proxy
    "proxyhost"     ? string # comma-separated list of proxy hosts
    "proxyport"     ? string # proxy port number
    "proxyrandom"   ? boolean_yes_no # randomize proxyhost
    "proxytype"     ? string with match (SELF, '^(forward|reverse)$') # select proxy type, forward or reverse
    "rpmexclusive"  ? boolean_yes_no # stop other processes using rpm db
    "run"           ? boolean_yes_no # Run the SPMA after configuring it
    "tmpdir"        ? string # path to the temporary directory
    "trailprefix"   ? boolean # if no escape function, use underscore prefix
    "unescape"      ? boolean # use escape function
    "uninstpaths"   ? string[] # where to find uninstall definitions
    "userpkgs"      ? boolean_yes_no # Allow user packages
    "userprio"      ? boolean_yes_no # Priority to user packages
    "usespmlist"    ? boolean_yes_no # Have SPMA controlling any packages
    "verbose"       ? string with match (SELF, '^(0|1)$') # verbose (0,1)
};

bind "/software/components/spma" = component_spma_type;
bind "/software/groups" = SOFTWARE_GROUP{};
bind "/software/packages" = SOFTWARE_PACKAGE {} {};
bind "/software/repositories" = SOFTWARE_REPOSITORY [];
