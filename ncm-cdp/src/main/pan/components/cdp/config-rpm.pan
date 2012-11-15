# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/cdp/config-rpm;
include { 'components/cdp/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/cdp/dependencies/pre' ?= list('spma');

'/software/components/cdp/version' = '${project.version}';

