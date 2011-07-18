# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/sendmail
#
#
############################################################
 
unique template components/sendmail/config-rpm;
include { 'components/sendmail/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-sendmail","1.6.5-1","noarch");
 
"/software/components/sendmail/dependencies/pre" ?= list("spma");
"/software/components/sendmail/active" ?= true;
"/software/components/sendmail/dispatch" ?= true;
 
