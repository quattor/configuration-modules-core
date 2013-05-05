# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config-rpm;

include { 'components/${project.artifactId}/config-common' };

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

# Install Quattor configuration module via RPM package.
'/software/packages' = pkg_repl('ncm-${project.artifactId}','${no-snapshot-version}-${rpm.release}','noarch');
'dependencies/pre' ?= list('spma');

