# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/gpfs/config-rpm;
include { 'components/gpfs/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-gpfs","0.6.1-4","noarch");

'/software/components/gpfs/version' ?= '${project.version}';

"/software/components/gpfs/dependencies/pre" ?= list("spma");
"/software/components/gpfs/active" ?= true;
"/software/components/gpfs/dispatch" ?= true;
