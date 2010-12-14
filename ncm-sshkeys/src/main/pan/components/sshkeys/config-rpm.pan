# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/sshkeys/config-rpm;
include components/sshkeys/schema;

# Package to install
'/software/packages'=pkg_repl('ncm-sshkeys','1.1.5-1','noarch');
'/software/components/sshkeys/dependencies/pre' ?= list('spma');

'/software/components/sshkeys/version' = '1.1.5';

