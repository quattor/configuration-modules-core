# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include { 'components/${project.artifactId}/schema' };
include { 'components/${project.artifactId}/config-rpm' };

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

'active' ?= true;
'dispatch' ?= true;

