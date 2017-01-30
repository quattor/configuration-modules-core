# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/fstab/config-rpm;

include 'components/fstab/schema';

"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/fstab/dependencies/pre" = list ("spma");
"/software/components/fstab/active" ?= true;
"/software/components/fstab/dispatch" ?= true;
"/software/components/fstab/register_change" = list ("/system/filesystems");
