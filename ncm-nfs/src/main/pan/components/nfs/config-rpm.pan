# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/nfs/config-rpm;
include { 'components/nfs/schema' };
 
# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

'/software/components/nfs/dependencies/pre' ?= list('spma');

'/software/components/nfs/version' = '${project.version}';
  
