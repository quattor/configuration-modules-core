# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/hostsaccess/config-rpm;
include 'components/hostsaccess/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/hostsaccess/dependencies/pre' ?= list('spma');

'/software/components/hostsaccess/version' = '${no-snapshot-version}';
