# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/iptables/config-rpm;
include { "components/iptables/schema" };

# Package to install.
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");


# standard component settings
"/software/components/iptables/active" ?=  true ;
"/software/components/iptables/dispatch" ?=  true ;
#"/software/components/iptables/dependencies/pre" = push("spma");

