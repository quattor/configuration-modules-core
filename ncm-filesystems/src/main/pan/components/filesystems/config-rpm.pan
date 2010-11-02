# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/filesystems/config-rpm;

include {'components/filesystems/schema'};

include {'components/fstab/config'};

"/software/packages" = pkg_repl ("ncm-filesystems", "1.0.0-1", "noarch");
"/software/components/filesystems/dependencies/post" = list ("fstab");
"/software/components/filesystems/dependencies/pre" = list ("spma");
"/software/components/filesystems/active" ?= true;
"/software/components/filesystems/dispatch" ?= true;
"/software/components/filesystems/register_change" = list ("/system/filesystems", "/system/blockdevices");
