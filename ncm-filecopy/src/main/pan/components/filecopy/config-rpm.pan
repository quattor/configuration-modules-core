# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/filecopy/config-rpm;
include 'components/filecopy/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/filecopy/dependencies/pre' ?= list('spma');

'/software/components/filecopy/version' = '${no-snapshot-version}';

