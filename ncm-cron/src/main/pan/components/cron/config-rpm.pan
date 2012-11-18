# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/cron/config-rpm;
include { 'components/cron/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/cron/dependencies/pre' ?= list('spma');

'/software/components/cron/version' = '${no-snapshot-version}';
