# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ipmi/config-rpm;

include { 'components/ipmi/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-ipmi","1.0.3-1","noarch");

'/software/components/ipmi/version' = '1.0.3';

"/software/components/ipmi/dependencies/post" ?= list("spma");
"/software/components/ipmi/active" ?= true;
"/software/components/ipmi/dispatch" ?= true;

