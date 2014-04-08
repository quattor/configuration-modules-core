# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ntpd/config-rpm;
include { 'components/ntpd/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/ntpd/version' ?= '${no-snapshot-version}';

"/software/components/ntpd/dependencies/pre" ?= list("spma");
