# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';
include 'pan/functions';

"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

prefix '/software/components/${project.artifactId}';

'version' = '${no-snapshot-version}';
'active' ?= true;
'dispatch' ?= true;
'dependencies/pre' ?= list("spma");
