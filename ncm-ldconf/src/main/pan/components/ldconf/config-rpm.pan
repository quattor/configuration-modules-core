# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ldconf/config-rpm;
include 'components/ldconf/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/ldconf/dependencies/pre' ?= list('spma');

'/software/components/ldconf/version' = '${no-snapshot-version}';
