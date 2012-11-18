# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ssh/config-rpm;

include { 'components/ssh/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


'/software/components/ssh/version' ?= '${no-snapshot-version}';

"/software/components/ssh/dependencies/pre" ?= list("spma");
"/software/components/ssh/active" ?= true;
"/software/components/ssh/dispatch" ?= true;
