# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ssh/config-rpm;

include { 'components/ssh/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-ssh","2.0.4-1","noarch");

'/software/components/ssh/version' ?= '2.0.4';

"/software/components/ssh/dependencies/pre" ?= list("spma");
"/software/components/ssh/active" ?= true;
"/software/components/ssh/dispatch" ?= true;
