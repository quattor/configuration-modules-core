# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

bind "/software/components/${project.artifactId}" = component_chkconfig_type;

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';
'active' ?= true;
'dispatch' ?= true;
'dependencies/pre' ?= list("spma");

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
