# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

variable CEPH_SCHEMA_VERSION ?= 'v1';
include 'components/${project.artifactId}/config-rpm';
