# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/shorewall/config-rpm;
include { 'components/shorewall/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-shorewall","0.5.4-2","noarch");

'/software/components/shorewall/version' ?= '0.5.4';

"/software/components/shorewall/dependencies/pre" ?= list("spma");
"/software/components/shorewall/active" ?= true;
"/software/components/shorewall/dispatch" ?= true;
