# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/mysql/config-rpm;
include { 'components/mysql/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

 
'/software/components/mysql/version' ?= '${project.version}';

"/software/components/mysql/dependencies/pre" ?= list("spma");
"/software/components/mysql/active" ?= true;
"/software/components/mysql/dispatch" ?= true;
