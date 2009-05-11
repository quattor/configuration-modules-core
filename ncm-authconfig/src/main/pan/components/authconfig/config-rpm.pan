# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/authconfig/config-rpm;
include components/authconfig/schema;

# Package to install
"/software/packages"=pkg_repl("ncm-authconfig","1.1.16-1","noarch");

"/software/components/authconfig/dependencies/pre" ?= list("spma");
"/software/components/authconfig/active" ?= true;
"/software/components/authconfig/dispatch" ?= true;

"/software/components/authconfig/safemode" ?= false;

"/software/components/authconfig/usemd5" ?= true;
"/software/components/authconfig/useshadow" ?= true;
"/software/components/authconfig/usecache" ?= true;

