# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/networkupstools/config-rpm;

include {'components/networkupstools/schema'};

"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

"/software/components/networkupstools/dependencies/pre" = list ("spma");
"/software/components/networkupstools/active" ?= true;
"/software/components/networkupstools/dispatch" ?= true;


