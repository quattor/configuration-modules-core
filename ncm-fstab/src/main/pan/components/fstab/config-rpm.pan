# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/fstab/config-rpm;

include {'components/fstab/schema'};

#"/software/packages" = pkg_repl ("ncm-fstab", "0.1.0-1", "noarch");
"/software/components/fstab/dependencies/pre" = list ();
"/software/components/fstab/active" ?= true;
"/software/components/fstab/dispatch" ?= true;
"/software/components/fstab/register_change" = list ("/system/filesystems");
