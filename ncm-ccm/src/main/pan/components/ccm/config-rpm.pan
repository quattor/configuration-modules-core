# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ccm/config-rpm;
include {'components/ccm/schema'};

# Package to install
'/software/packages'=pkg_repl('ncm-ccm','1.2.0-1','noarch');
'/software/components/ccm/dependencies/pre' ?= list('spma');

'/software/components/ccm/version' ?= '1.2.0';

