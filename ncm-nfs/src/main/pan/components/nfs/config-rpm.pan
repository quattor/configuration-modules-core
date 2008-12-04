# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/nfs/config-rpm;
include components/nfs/schema;
 
# Package to install
'/software/packages'=pkg_repl('ncm-nfs','1.1.8-1','noarch');
'/software/components/nfs/dependencies/pre' ?= list('spma');

'/software/components/nfs/version' = '1.1.8';
  
