# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/postfix/config-rpm;

include { 'components/postfix/config-common' };

# Set prefix to root of component configuration.
prefix '/software/components/postfix';

# Install Quattor configuration module via RPM package.
'/software/packages' = pkg_repl('ncm-postfix','${no-snapshot-version}-${rpm.release}','noarch');
'dependencies/pre' ?= list('spma');

