# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}


unique template components/accounts/config;

include { 'components/${project.artifactId}/schema' };
include { 'components/${project.artifactId}/functions' };

# Define configuration module default configuration
prefix '/software/components/${project.artifactId}';
'active' ?= true;
'dispatch' ?= true;
'dependencies/pre' ?= list('spma');
'version' = '${no-snapshot-version}';

# Include system users and groups which shouldn't be removed
# by default.  The machine configuration can still modify or
# remove them manually.
include { 'components/accounts/sysgroups' };
include { 'components/accounts/sysusers' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

