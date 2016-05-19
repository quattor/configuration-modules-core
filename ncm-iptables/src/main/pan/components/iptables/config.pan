# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include "components/${project.artifactId}/schema";

# Package to install.
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

prefix '/software/components/${project.artifactId}';

'active' ?= true;
'dispatch' ?= true;
'dependencies/pre' = append("spma");
