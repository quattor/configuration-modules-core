# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/dnf/config;

prefix '/software';
# Package to install
'packages' = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

# Set prefix to root of component configuration.
prefix '/software/components/spma';

'register_change' ?= list("/software/packages", "/software/repositories");
