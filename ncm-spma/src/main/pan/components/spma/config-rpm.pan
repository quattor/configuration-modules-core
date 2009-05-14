# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/spma/config-rpm;
include { 'components/spma/schema' };
include { 'components/spma/functions' };

# Package to install
"/software/packages" = pkg_repl("ncm-spma","1.6.0-3","noarch");

"/software/components/spma/active" ?= true;
"/software/components/spma/dispatch" ?= true;
"/software/components/spma/register_change" ?= list("/software/packages");

"/software/components/spma/run" ?= "yes";
