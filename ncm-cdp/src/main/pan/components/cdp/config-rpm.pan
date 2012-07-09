# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/cdp/config-rpm;
include { 'components/cdp/schema' };

# Package to install
'/software/packages'=pkg_repl('ncm-cdp','1.0.4-1','noarch');
'/software/components/cdp/dependencies/pre' ?= list('spma');

'/software/components/cdp/version' = '${project.version}';

