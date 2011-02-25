# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/accounts/config-rpm;

include { 'components/accounts/schema' };
include { 'components/accounts/functions' };

# Package to install
'/software/packages'=pkg_repl('ncm-accounts','5.1.5-1','noarch');
'/software/components/accounts/dependencies/pre' ?= list('spma');

'/software/components/accounts/version' = '5.1.5';
 
# Include system users and groups which shouldn't be removed
# by default.  The machine configuration can still modify or
# remove them manually.
include { 'components/accounts/sysgroups' };
include { 'components/accounts/sysusers' };

'/software/components/accounts/active' ?= true;
'/software/components/accounts/dispatch' ?= true;
