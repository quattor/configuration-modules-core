# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/dirperm/config-rpm;
include { "components/dirperm/schema" };

# Package to install
'/software/packages'=pkg_repl('ncm-dirperm','1.5.0-1','noarch');
'/software/components/dirperm/dependencies/pre' ?= list('spma');

'/software/components/dirperm/version' = '1.5.0';
 
