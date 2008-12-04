# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/apt/config-rpm;
include components/apt/schema;

# Package to install
"/software/packages" = pkg_repl("ncm-apt","0.1.0-1","noarch");
 
"/software/components/apt/active"    = true;
"/software/components/apt/dispatch" ?= true;
