# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

'/software/packages'=pkg_repl('ncm-${project.artifactId}','${no-snapshot-version}-${RELEASE}','noarch');

prefix '/software/components/${project.artifactId}';
'dependencies/pre' ?= list ('spma');
'active' ?= true;
'dispatch' ?= true;
'version' = '${no-snapshot-version}';
