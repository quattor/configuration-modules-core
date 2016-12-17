# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

unique template components/${project.artifactId}/config;

include 'components/${project.artifactId}/schema';

bind "/software/components/grub" = component_grub_type;

# Package to install.
'/software/packages' = pkg_repl('ncm-${project.artifactId}', '${no-snapshot-version}-${rpm.release}', 'noarch');

# Set prefix to root of component configuration.
prefix '/software/components/${project.artifactId}';

'version' = '${no-snapshot-version}';
'active' ?= true;
'dispatch' ?= true;
'dependencies/pre' = append('spma');
# Do not register for changes to /system/kernel/version as it is optional
'register_change' = append('/system/kernel');
