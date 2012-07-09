# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/sindes_getcert/config-rpm;
include {'components/sindes_getcert/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");

 
"/software/components/sindes_getcert/dependencies/pre" ?= list("spma");
"/software/components/sindes_getcert/active" ?= true;
"/software/components/sindes_getcert/dispatch" ?= true;

##
## set the sindes values + ccm cert config
## default has most used parameters set with variables
##
variable SINDES_GETCERT_SETUP ?= "components/sindes_getcert/default"; 
include { SINDES_GETCERT_SETUP };