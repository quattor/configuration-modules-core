# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/spma/apt/config;

prefix '/software';

'packages' = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

prefix '/software/components/${project.artifactId}';

'packager' = 'apt';

'register_change' ?= list(
    "/software/packages",
    "/software/repositories",
);
