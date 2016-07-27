# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/schema;

include 'quattor/types/component';
include 'components/spma/functions';
include 'components/spma/software';

type component_spma_common = {
    "cmdfile"       : string = "/var/tmp/spma-commands" # where to save commands for spma-run script
    "packager"      : string = "yum" with match (SELF, '^(yum|ips)$') # system packager to be used (yum,ips,rpm)
    "pkgpaths"      : string[] = list("/software/packages") # where to find package definitions
    "process_obsoletes" : boolean = false
    "cachedir"      ? string # SPMA cache directory
    "debug"         ? string with match (SELF, '^(0|1|2|3|4|5)$') # debug level (0-5)
    "flagfile"      ? string # touch this file if there is work to do (i.e. spma-run --execute)
    "headnode"      ? boolean # use head node
    "localcache"    ? legacy_binary_affirmation_string # Use SPMA package cache
    "protectkernel" ? legacy_binary_affirmation_string # Prevent currrent kernel from being removed
    "proxy"         ? legacy_binary_affirmation_string # Enable proxy
    "proxyhost"     ? string # comma-separated list of proxy hosts
    "proxyport"     ? string # proxy port number
    "proxyrandom"   ? legacy_binary_affirmation_string # randomize proxyhost
    "proxytype"     ? string with match (SELF, '^(forward|reverse)$') # select proxy type, forward or reverse
    "rpmexclusive"  ? legacy_binary_affirmation_string # stop other processes using rpm db
    "run"           ? legacy_binary_affirmation_string # Run the SPMA after configuring it
    "tmpdir"        ? string # path to the temporary directory
    "trailprefix"   ? boolean # if no escape function, use underscore prefix
    "unescape"      ? boolean # use escape function
    "uninstpaths"   ? string[] # where to find uninstall definitions
    "userpkgs"      ? legacy_binary_affirmation_string # Allow user packages
    "userprio"      ? legacy_binary_affirmation_string # Priority to user packages
    "usespmlist"    ? legacy_binary_affirmation_string # Have SPMA controlling any packages
    "verbose"       ? string with match (SELF, '^(0|1)$') # verbose (0,1)
};

bind "/software/packages" = SOFTWARE_PACKAGE {} {};
bind "/software/repositories" = SOFTWARE_REPOSITORY [];
