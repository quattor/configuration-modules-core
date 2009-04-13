# ${license-info}
# ${developer-info}
# ${author-info}

  
unique template components/filecopy/config-rpm;
include { 'components/filecopy/schema' };
 
# Package to install
'/software/packages'=pkg_repl('ncm-filecopy','1.3.4-2','noarch');
'/software/components/filecopy/dependencies/pre' ?= list('spma');

'/software/components/filecopy/version' = '1.3.4';
  
