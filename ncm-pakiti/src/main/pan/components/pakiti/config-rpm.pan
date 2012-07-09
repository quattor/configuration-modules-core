# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/pakiti/config-rpm;


include {'components/pakiti/schema'};

# Package to install.
"/software/packages"=pkg_repl("ncm-pakiti","1.0.0-1","noarch");

# standard component settings
"/software/components/pakiti/active" ?=  true ;
"/software/components/pakiti/dispatch" ?=  true ;
