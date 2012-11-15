# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/pakiti/config-rpm;


include {'components/pakiti/schema'};

# Package to install.
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


# standard component settings
"/software/components/pakiti/active" ?=  true ;
"/software/components/pakiti/dispatch" ?=  true ;
