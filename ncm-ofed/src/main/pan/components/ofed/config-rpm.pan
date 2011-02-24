# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ofed/config-rpm;
include { 'components/ofed/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-ofed","0.5.0-1","noarch");

'/software/components/ofed/version' ?= '0.5.0';

"/software/components/ofed/dependencies/pre" ?= list("spma");
"/software/components/ofed/active" ?= true;
"/software/components/ofed/dispatch" ?= true;
