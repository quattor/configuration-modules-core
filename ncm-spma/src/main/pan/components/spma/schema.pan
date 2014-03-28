# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/spma/schema;

include { 'quattor/schema' };
include { 'components/spma/functions' };
include { 'components/spma/ips/schema' };

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
    "name" : string  # "Package name"
    "version" : string  # "Package version"
    "arch" : string  # "Package architecture"
};

type SOFTWARE_REPOSITORY_PROTOCOL = {
    "name" : string  # "Protocol name"
    "url" : string  # "URL for the given protocol"
    "cacert" ? string  # Path to CA certificate
    "clientkey" ? string # Path to client key
    "clientcert" ? string # Path to client certificate
    "verify" ? boolean # Whether to verify the SSL certificate
};

type SOFTWARE_REPOSITORY = {
    "name" ? string  # "Repository name"
    "owner" ? string  # "Contact person (email)"
    "protocols" ? SOFTWARE_REPOSITORY_PROTOCOL []
    "priority" ? long(1..99)
    "enabled" : boolean = true
    "gpgcheck" : boolean = false
    "includepkgs" ? string[]
    "excludepkgs" ? string[]
    "skip_if_unavailable" : boolean = false
    "proxy" ? string with SELF == '' || is_absoluteURI(SELF)
};

type SOFTWARE_GROUP = {
    "mandatory" : boolean = true
    "optional" : boolean = false
    "default" : boolean = true
};

type component_spma_type = {
    include structure_component
    include component_spma_ips
    "tmpdir"        ? string # path to the temporary directory
    "unescape"      ? boolean # use escape function
    "trailprefix"   ? boolean # if no escape function, use underscore prefix
    "userpkgs"      ? string with match (SELF, 'yes|no') # Allow user packages
    "userprio"      ? string with match (SELF, 'yes|no') # Priority to user packages
    "protectkernel" ? string with match (SELF, 'yes|no') # Prevent currrent kernel from being removed
    "packager"      : string = "yum" with match (SELF, '(yum|ips)') # system packager to be used (yum,ips)
    "rpmexclusive"  ? string with match (SELF, 'yes|no') # stop other processes using rpm db
    "usespmlist"    ? string with match (SELF, 'yes|no') # Have SPMA controlling any packages
    "debug"         ? string with match (SELF, '0|1|2|3|4|5') # debug level (0-5)
    "verbose"       ? string with match (SELF, '0|1') # verbose (0,1)
    "localcache"    ? string with match (SELF, 'yes|no') # Use SPMA package cache
    "cachedir"      ? string # SPMA cache directory
    "run"           ? string with match (SELF, 'yes|no') # Run the SPMA after configuring it
    "proxy"         ? string with match (SELF, 'yes|no') # Enable proxy
    "proxytype"     ? string with match (SELF, 'forward|reverse') # select proxy type, forward or reverse
    "proxyhost"     ? string # comma-separated list of proxy hosts
    "proxyport"     ? string # proxy port number
    "proxyrandom"   ? string with match (SELF, 'yes|no') # randomize proxyhost
    "headnode"      ? boolean # use head node
    "process_obsoletes" : boolean = false
    "pkgpaths"      : string[] = list("/software/packages") # where to find package definitions
    "uninstpaths"   ? string[] # where to find uninstall definitions
    "cmdfile"       : string = "/var/tmp/spma-commands" # where to save commands for spma-run script
    "flagfile"      ? string # touch this file if there is work to do (i.e. spma-run --execute)
};

bind "/software/components/spma" = component_spma_type;
bind '/software/repositories' = SOFTWARE_REPOSITORY [];
bind '/software/packages' = SOFTWARE_PACKAGE {} {};
bind "/software/groups" = SOFTWARE_GROUP{};
