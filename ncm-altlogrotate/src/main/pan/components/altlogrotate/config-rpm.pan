# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/altlogrotate/config-rpm;
include { 'components/altlogrotate/schema' };

# Package to install
'/software/packages'=pkg_repl('ncm-altlogrotate','1.1.8-1','noarch');
'/software/components/altlogrotate/dependencies/pre' ?= list('spma');

'/software/components/altlogrotate/version' = '1.1.8';
