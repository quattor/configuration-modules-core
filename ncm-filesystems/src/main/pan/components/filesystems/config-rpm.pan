# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/filesystems/config-rpm;

include {'components/filesystems/schema'};

"/software/packages" = pkg_repl ("ncm-filesystems", "0.10.4-1", "noarch");
"/software/components/filesystems/dependencies/pre" = list ("spma");
"/software/components/filesystems/active" ?= true;
"/software/components/filesystems/dispatch" ?= true;
#"/software/components/filesystems/register_change" = list ("/system/filesystems", "/system/blockdevices");

