# ${license-info}
# ${developer-info}
# ${author-info}

 
unique template components/sysconfig/config-rpm;
include components/sysconfig/schema;
 
# Package to install
'/software/packages'=pkg_repl('ncm-sysconfig','1.2.0-1','noarch');
'/software/components/sysconfig/dependencies/pre' ?= list('spma');

'/software/components/sysconfig/version' ?= '1.2.0';
