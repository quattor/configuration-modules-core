# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/ntpd/config-rpm;
include { 'components/ntpd/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-ntpd","1.1.5-1","noarch");

'/software/components/ntpd/version' ?= '${project.version}';

"/software/components/ntpd/dependencies/pre" ?= list("spma");
"/software/components/ntpd/active" ?= true;
"/software/components/ntpd/dispatch" ?= true;
