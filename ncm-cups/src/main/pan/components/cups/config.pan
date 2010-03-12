################################################################################
# This is 'TPL/config.tpl', a ncm-cups's file
################################################################################
#
# VERSION:    2.0.0, 12/03/10 16:19
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
"/software/packages"=pkg_repl("ncm-cups","2.0.0-1","noarch");

'/software/components/cups/version' = '2.0.0';

"/software/components/cups/dependencies/pre" ?= list("spma");

