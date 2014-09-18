# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/${project.artifactId}/config-rpm;
include {'components/${project.artifactId}/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/${project.artifactId}/dependencies/pre' ?= list('spma');

'/software/components/${project.artifactId}/version' ?= '${no-snapshot-version}';

