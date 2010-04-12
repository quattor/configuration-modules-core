# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/mysql/config-rpm;
include { 'components/mysql/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-mysql","1.2.1-1","noarch");
 
'/software/components/mysql/version' ?= '1.2.1';

"/software/components/mysql/dependencies/pre" ?= list("spma");
"/software/components/mysql/active" ?= true;
"/software/components/mysql/dispatch" ?= true;
