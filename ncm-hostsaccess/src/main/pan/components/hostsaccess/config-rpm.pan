# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/hostsaccess/config-rpm;
include components/hostsaccess/schema;

# Package to install
'/software/packages'=pkg_repl('ncm-hostsaccess','1.1.3-1','noarch');
'/software/components/hostsaccess/dependencies/pre' ?= list('spma');

'/software/components/hostsaccess/version' = '1.1.3';
