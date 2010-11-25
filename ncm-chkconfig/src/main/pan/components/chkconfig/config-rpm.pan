# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/chkconfig
#
#
#
############################################################
 
unique template components/chkconfig/config-rpm;
include { 'components/chkconfig/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-chkconfig","1.2.0-1","noarch");
 
"/software/components/chkconfig/dependencies/pre" ?= list("spma");
"/software/components/chkconfig/active" ?= true;
"/software/components/chkconfig/dispatch" ?= true;
 
