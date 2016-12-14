# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ipmi/config-rpm;

include 'components/ipmi/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


'/software/components/ipmi/version' = '${no-snapshot-version}';

"/software/components/ipmi/dependencies/post" ?= list("spma");
"/software/components/ipmi/active" ?= true;
"/software/components/ipmi/dispatch" ?= true;

