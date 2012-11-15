# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/mailaliases/config-rpm;

include {'components/mailaliases/schema'};

# Package to install.
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


# standard component settings
"/software/components/mailaliases/active" ?=  true ;
"/software/components/mailaliases/dispatch" ?=  true ;
#"/software/components/mailaliases/dependencies/pre" = push( "spma" );


