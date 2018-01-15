# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

variable CEPH_SCHEMA_VERSION ?= 'v1';

include format('components/${project.artifactId}/%s/schema', CEPH_SCHEMA_VERSION);

prefix '/software/components/${project.artifactId}';

'version' = '${no-snapshot-version}';
'active' ?= true;
'dispatch' ?= true;

'/software/packages' = pkg_repl('ncm-${project.artifactId}','${no-snapshot-version}-${rpm.release}','noarch');
'dependencies/pre' ?= list('spma', 'accounts', 'sudo', 'useraccess');

bind '/software/components/${project.artifactId}' = ${project.artifactId}_component;
