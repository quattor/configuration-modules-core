# ${license-info}
# ${developer-info}
# ${author-info}

  
unique template components/ldconf/config-rpm;
include {'components/ldconf/schema'};
 
# Package to install
'/software/packages'=pkg_repl('ncm-ldconf','1.3.3-1','noarch');
'/software/components/ldconf/dependencies/pre' ?= list('spma');

'/software/components/ldconf/version' = '1.3.3';
