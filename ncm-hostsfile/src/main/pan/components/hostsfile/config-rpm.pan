# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/hostsfile/config-rpm;
include { 'components/hostsfile/schema' };

"/software/components/hostsfile/active" ?= false;
"/software/components/hostsfile/dispatch" ?= false;

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/hostsfile/version' = '${project.version}';
