# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/dnf/config;

prefix '/software';
# Package to install
'packages' = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
# modules can be empty, when nothing is set
"modules" ?= dict();

# Set prefix to root of component configuration.
prefix '/software/components/spma';

'register_change' ?= list("/software/packages", "/software/repositories", "/software/modules");
