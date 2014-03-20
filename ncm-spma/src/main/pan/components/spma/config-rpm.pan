# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/spma/config-rpm;
include { 'components/spma/schema' };
include { 'components/spma/functions' };

include { 'components/spma/config-common' };

variable PACKAGE_MANAGER = 'yum';

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

# Package to install
'packages' = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'packager' = PACKAGE_MANAGER;
'register_change' ?= list("/software/packages",
                          "/software/repositories");
'run' ?= "yes";
