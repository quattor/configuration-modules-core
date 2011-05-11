# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/postgresql
#
#
#
#
############################################################

unique template components/postgresql/config-rpm;
include {'components/postgresql/schema'};

# Package to install
"/software/packages"=pkg_repl("ncm-postgresql","0.1.4-1","noarch");
 
 ## chkconfig is needed because the component can start postgres using the start script
"/software/components/postgresql/dependencies/pre" ?= list("spma","chkconfig");
"/software/components/postgresql/active" ?= true;
"/software/components/postgresql/dispatch" ?= true;
