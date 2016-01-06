# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-rpm;

include { 'components/accounts/schema' };
include { 'components/accounts/functions' };
include { 'components/${project.artifactId}/config-common'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/accounts/dependencies/pre' ?= list('spma');

'/software/components/accounts/version' = '${no-snapshot-version}';

# Include system users and groups which shouldn't be removed
# by default.  The machine configuration can still modify or
# remove them manually.
include { 'components/accounts/sysgroups' };
include { 'components/accounts/sysusers' };
