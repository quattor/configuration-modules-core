# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/sshkeys/config-rpm;

include { 'components/sshkeys/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

'/software/components/sshkeys/dependencies/pre' ?= list('spma');

'/software/components/sshkeys/version' = '${project.version}';

