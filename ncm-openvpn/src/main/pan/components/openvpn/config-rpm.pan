# ${license-info}
# ${developer-info}
# ${author-info}

################################################################################
# This is 'TPL/config.tpl', a ncm-openvpn's file
################################################################################
#
#
################################################################################
unique template components/openvpn/config-rpm;
include {'components/openvpn/schema'};

# Package to install
"/software/packages" = pkg_repl("ncm-${project.artifactId}", "${no-snapshot-version}-${rpm.release}", "noarch");

"/software/components/openvpn/dependencies/pre" ?=  list ("spma");

"/software/components/openvpn/active" ?= true;
"/software/components/openvpn/dispatch" ?= true;

