# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/nfs/config-rpm;
include { 'components/nfs/schema' };
 
# Package to install
'/software/packages'=pkg_repl('ncm-nfs','2.0.0-1','noarch');
'/software/components/nfs/dependencies/pre' ?= list('spma');

'/software/components/nfs/version' = '2.0.0';
  
