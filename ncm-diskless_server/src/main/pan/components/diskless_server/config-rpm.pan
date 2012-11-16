# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/${project.artifactId}/config-rpm;
include {'components/${project.artifactId}/schema'};

# Common settings
#"/software/components/diskless_server/dependencies/pre" = list("spma");
"/software/components/diskless_server/active" = true;
"/software/components/diskless_server/dispatch" ?= true;
"/software/packages" = pkg_repl("${project.artifactId}", "${no-snapshot-version}-${rpm.version}", "noarch");
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
