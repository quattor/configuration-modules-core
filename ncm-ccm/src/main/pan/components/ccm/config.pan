# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

bind '/software/components/ccm' = component_ccm;

'/software/packages' = pkg_repl('ncm-${project.artifactId}','${no-snapshot-version}-${RELEASE}','noarch');

prefix '/software/components/${project.artifactId}';
'dependencies/pre' ?= list('spma');
'active' ?= true;
'dispatch' ?= true;
'version' ?= '${no-snapshot-version}';
