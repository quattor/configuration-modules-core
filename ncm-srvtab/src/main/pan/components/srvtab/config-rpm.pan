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
"/software/packages"=pkg_repl("ncm-srvtab","1.2.2-1","noarch");
 
"/software/components/srvtab/active" ?= true;
"/software/components/srvtab/verbose" ?= false;
"/software/components/srvtab/overwrite" ?= false;
"/software/components/srvtab/server" ?= "configure.your.arc.server";
 
