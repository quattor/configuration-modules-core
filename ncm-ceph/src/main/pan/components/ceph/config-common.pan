# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-common;

prefix '/software/components/${project.artifactId}';
include format('components/${project.artifactId}/%s/schema', CEPH_SCHEMA_VERSION);

'version' = '${no-snapshot-version}';

'active' ?= true;
'dispatch' ?= true;
