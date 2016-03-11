# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include "components/dirperm/schema";

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

prefix '/software/components/${project.artifactId}';

'dependencies/pre' ?= list('spma');
'register_change' ?= list('/system/filesystems');
'version' = '${no-snapshot-version}';
'active' ?= true;
'dispatch' ?= true;
