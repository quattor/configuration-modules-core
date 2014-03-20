# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-common;

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

#'version' = '${project.version}';
#'package' = 'NCM::Component';

'run' ?= "yes";
'active' ?= true;
'dispatch' ?= true;
