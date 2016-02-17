# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

variable CONFIG_MODULES_CONFIG_SUFFIX ?= 'rpm';

include format('components/${project.artifactId}/%s/schema', CONFIG_MODULES_CONFIG_SUFFIX);
include { 'components/${project.artifactId}/functions' };

include { 'components/${project.artifactId}/config-common' };
include { 'components/${project.artifactId}/config-'+CONFIG_MODULES_CONFIG_SUFFIX };
