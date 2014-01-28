# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/spma/config-rpm;
include { 'components/spma/schema' };
include { 'components/spma/functions' };

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


"/software/components/spma/active" ?= true;
"/software/components/spma/dispatch" ?= true;
"/software/components/spma/register_change" ?= list("/software/packages",
                                                    "/software/repositories");

"/software/components/spma/run" ?= "yes";
