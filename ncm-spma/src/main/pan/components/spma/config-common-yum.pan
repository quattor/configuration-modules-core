unique template components/spma/config-common-yum;

# Prefix for packages/groups
prefix '/software';
'groups' ?= dict();

# Package to install
'packages' = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';
'register_change' ?= list(
    "/software/groups",
    "/software/packages",
    "/software/repositories",
);
