# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/afsclt/config-rpm;
include { 'components/afsclt/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-afsclt","1.5.6-1","noarch");
 
"/software/components/afsclt/dependencies/pre" ?= list("spma");
"/software/components/afsclt/active" ?= true;
"/software/components/afsclt/dispatch" ?= true;
 
