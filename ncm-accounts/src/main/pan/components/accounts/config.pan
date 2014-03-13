# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/accounts/config;

include { 'components/${project.artifactId}/schema' };
include { 'components/${project.artifactId}/functions' };
include { 'components/${project.artifactId}/config-common' };
include { 'components/${project.artifactId}/config-rpm' };

# Package to install
