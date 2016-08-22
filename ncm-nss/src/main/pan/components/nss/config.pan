# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

include 'pan/functions';

# Package to install.
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

# standard component settings
prefix '/software/components/${project.artifactId}';
'active' ?= true;
'dispatch' ?= true;
'version' = "${no-snapshot-version}";
