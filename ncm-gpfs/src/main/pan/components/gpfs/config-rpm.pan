# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/gpfs/config-rpm;
include { 'components/gpfs/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


'/software/components/gpfs/version' ?= '${project.version}';

"/software/components/gpfs/dependencies/pre" ?= list("spma");
"/software/components/gpfs/active" ?= true;
"/software/components/gpfs/dispatch" ?= true;
