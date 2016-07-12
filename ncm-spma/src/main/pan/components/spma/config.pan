# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

variable SPMA_BACKEND ?= 'rpm';

include format('components/${project.artifactId}/%s/schema', SPMA_BACKEND);
include 'components/${project.artifactId}/functions';

include 'components/${project.artifactId}/config-common';
include format('components/${project.artifactId}/config-%s', SPMA_BACKEND);
