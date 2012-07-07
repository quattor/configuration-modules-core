# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/tomcat/config-rpm;

include { 'components/tomcat/schema' };

 
# Package to install
"/software/packages"=pkg_repl('ncm-tomcat', '1.1.2-1', 'noarch');

'/software/components/tomcat/version' ?= '1.1.2';

"/software/components/tomcat/dependencies/pre" ?= list("spma");
"/software/components/tomcat/active" ?= false;
"/software/components/tomcat/dispatch" ?= false;

