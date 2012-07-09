# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/sysctl/config-rpm;

include { 'components/sysctl/schema' };


# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

 
"/software/components/sysctl/dependencies/pre" ?= list("spma");
"/software/components/sysctl/active" ?= true;
"/software/components/sysctl/dispatch" ?= true;
 
