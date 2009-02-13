# ${license-info}
# ${developer-info}
# ${author-info}


unique template components/modprobe/config-rpm;
include { 'components/modprobe/schema' };

# Package to install
"/software/packages"=pkg_repl("ncm-modprobe","1.1.4-1","noarch");

"/software/components/modprobe/dependencies/pre" ?= list("spma");
"/software/components/modprobe/active" ?= true;
"/software/components/modprobe/dispatch" ?= true;

# Example for module <foo>
#"/software/components/modprobe/modules/1/name" = "foo";

