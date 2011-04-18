# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/gpfs/config-rpm;
include { 'components/gpfs/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-gpfs","0.5.2-2","noarch");

'/software/components/gpfs/version' ?= '0.5.2';

"/software/components/gpfs/dependencies/pre" ?= list("spma");
"/software/components/gpfs/active" ?= true;
"/software/components/gpfs/dispatch" ?= true;
