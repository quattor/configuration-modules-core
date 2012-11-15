# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/altlogrotate/config-rpm;
include { 'components/altlogrotate/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/altlogrotate/dependencies/pre' ?= list('spma');

'/software/components/altlogrotate/version' = '${project.version}';
