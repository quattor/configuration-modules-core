# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ofed/config-rpm;
include { 'components/ofed/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


'/software/components/ofed/version' ?= '${no-snapshot-version}';

"/software/components/ofed/dependencies/pre" ?= list("spma");
"/software/components/ofed/active" ?= true;
"/software/components/ofed/dispatch" ?= true;
