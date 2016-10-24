# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/yumng/config;

# Prefix for packages/groups
prefix '/software';

# Package to install
'packages' = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

'packager' = 'yumng';

'register_change' ?= list(
    "/software/groups",
    "/software/packages",
    "/software/repositories",
);
