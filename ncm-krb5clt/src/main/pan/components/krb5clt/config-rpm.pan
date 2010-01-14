# ${license-info}
# ${developer-info}
# ${author-info}

# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/krb5clt/config-rpm;
include components/krb5clt/schema;

# Package to install
"/software/packages"=pkg_repl("ncm-krb5clt","2.1.5-1","noarch");
 
"/software/components/krb5clt/dependencies/pre" ?= list("spma");
"/software/components/krb5clt/active" ?= true;
"/software/components/krb5clt/dispatch" ?= true;
 
