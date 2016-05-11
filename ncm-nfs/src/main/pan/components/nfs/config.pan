# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

bind '/software/components/nfs' = component_nfs;
    
prefix '/software/components/${project.artifactId}';
'active' ?= true;
'dispatch' ?= true;
'version' = '${no-snapshot-version}';
'dependencies/pre' ?= list('spma');

"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
