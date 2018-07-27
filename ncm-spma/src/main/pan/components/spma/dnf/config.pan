unique template components/spma/dnf/config;

prefix '/software';
# Package to install
'packages' = pkg_repl("ncm-spma");

# Set prefix to root of component configuration.
prefix '/software/components/spma';

'register_change' ?= list("/software/packages",
                          "/software/repositories");
