# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/iscsitarget/config-rpm;

include {'components/iscsitarget/schema'};

"/software/components/iscsitarget/active" ?= true;

"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
