# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/symlink
#
#
#
#
############################################################

unique template components/symlink/config-rpm;
include { 'components/symlink/schema' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

 
"/software/components/symlink/dependencies/pre" ?= list("spma");
"/software/components/symlink/active" ?= true;
"/software/components/symlink/dispatch" ?= true;
"/software/components/symlink/options/exists" ?= false;
"/software/components/symlink/options/replace/none" ?= "yes";
 
