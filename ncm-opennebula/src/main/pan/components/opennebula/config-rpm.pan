# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/opennebula/config-rpm;
include {'components/opennebula/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/opennebula/dependencies/pre' ?= list('spma');

'/software/components/opennebula/version' ?= '${no-snapshot-version}';

