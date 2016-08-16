# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

bind "/software/components/download" = component_download_type;

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';
'active' ?= true;
'dispatch' ?= true;
'version' = '${no-snapshot-version}';
'release' = '${rpm.release}';

"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
