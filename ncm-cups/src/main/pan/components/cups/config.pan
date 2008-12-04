################################################################################
# This is 'TPL/config.tpl', a ncm-cups's file
################################################################################
#
# VERSION:    1.1.3, 16/09/08 16:37
# AUTHOR:     Michel Jouvin <jouvin@lal.in2p3.fr>
# MAINTAINER: Luis Fernando Muñoz Mejías <mejias@delta.ft.uam.es>
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

unique template components/cups/config;
include {'components/cups/schema'};

# Package to install
"/software/packages"=pkg_repl("ncm-cups","1.1.3-1","noarch");

"/software/components/cups/dependencies/pre" ?=
  list("spma");
"/software/components/cups/active" ?= true;
"/software/components/cups/dispatch" ?= true;

