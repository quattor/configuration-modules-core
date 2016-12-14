# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/ganglia/config-rpm;

include 'components/ganglia/config-common';

# Set prefix to root of component configuration.
prefix '/software/components/ganglia';

# Install Quattor configuration module via RPM package.
'/software/packages' = pkg_repl('ncm-ganglia','${no-snapshot-version}-${RELEASE}','noarch');
'dependencies/pre' ?= list('spma');

