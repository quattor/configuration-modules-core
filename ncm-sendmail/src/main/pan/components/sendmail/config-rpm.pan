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
include 'components/sendmail/schema';

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


"/software/components/sendmail/dependencies/pre" ?= list("spma");
"/software/components/sendmail/active" ?= true;
"/software/components/sendmail/dispatch" ?= true;

