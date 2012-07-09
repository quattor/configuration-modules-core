# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/syslog/config-rpm;
include {'components/syslog/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");


"/software/components/syslog/dependencies/pre" ?= list("spma");
"/software/components/syslog/active" ?= true;
"/software/components/syslog/dispatch" ?= true;

