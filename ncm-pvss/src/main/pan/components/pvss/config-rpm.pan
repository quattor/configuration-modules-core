# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/${project.artifactId}/config-rpm;
include {'components/${project.artifactId}/schema'};

# Common settings
#"/software/components/${project.artifactId}/dependencies/pre" = list("spma");
"/software/components/${project.artifactId}/active" = true;
"/software/components/${project.artifactId}/dispatch" ?= true;
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");
