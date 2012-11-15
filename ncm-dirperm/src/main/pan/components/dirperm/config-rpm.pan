# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/dirperm/config-rpm;
include { "components/dirperm/schema" };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/dirperm/dependencies/pre' ?= list('spma');

'/software/components/dirperm/version' = '${project.version}';
 
