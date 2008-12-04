# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/oramonserver/config-rpm;

include components/oramonserver/schema;

# Package to install.
"/software/packages"=pkg_repl("ncm-oramonserver","1.0.16-1","noarch");

# standard component settings
"/software/components/oramonserver/dependencies/pre" = list("spma");
"/software/components/oramonserver/active" ?=  true ;
"/software/components/oramonserver/dispatch" ?=  true ;
"/software/components/oramonserver/register_change/0" = "/software/components/oramonserver";



