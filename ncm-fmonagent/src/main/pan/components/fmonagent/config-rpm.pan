# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/fmonagent/config-rpm;
include 'components/fmonagent/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


'/software/components/fmonagent/version' ?= '${no-snapshot-version}';

"/software/components/fmonagent/dependencies/pre" ?= list("spma");
"/software/components/fmonagent/active"         ?= true;
"/software/components/fmonagent/dispatch"         ?= true;
"/software/components/fmonagent/register_change"     ?= list("/system/monitoring");

