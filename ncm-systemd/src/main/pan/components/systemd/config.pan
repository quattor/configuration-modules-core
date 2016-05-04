# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;
include 'components/${project.artifactId}/schema';

include 'components/${project.artifactId}/functions';

bind '/software/components/${project.artifactId}' = component_${project.artifactId};

'/software/packages' = pkg_repl('ncm-${project.artifactId}','${no-snapshot-version}-${RELEASE}','noarch');

prefix '/software/components/${project.artifactId}';
'dependencies/pre' ?= list ('spma');
'active' ?= true;
'dispatch' ?= true;
