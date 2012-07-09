# ${license-info}
# ${developer-info}
# ${author-info}



unique template components/tomcat/config-rpm;

include { 'components/tomcat/schema' };

 
# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${RELEASE}", "noarch");


'/software/components/tomcat/version' ?= '${project.version}';

"/software/components/tomcat/dependencies/pre" ?= list("spma");
"/software/components/tomcat/active" ?= false;
"/software/components/tomcat/dispatch" ?= false;

