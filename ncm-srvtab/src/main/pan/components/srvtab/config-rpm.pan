# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/srvtab
#
#
############################################################
 
unique template components/srvtab/config-rpm;
include {'components/srvtab/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

 
"/software/components/srvtab/active" ?= true;
"/software/components/srvtab/verbose" ?= false;
"/software/components/srvtab/overwrite" ?= false;
"/software/components/srvtab/server" ?= "configure.your.arc.server";
 
