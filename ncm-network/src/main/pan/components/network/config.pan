################################################################################
# This is 'TPL/config.tpl', a ncm-network's file
################################################################################
#
# VERSION:    0.2.5, 04/07/08 20:02
# AUTHOR:     Stijn De Weirdt 
# MAINTAINER: Stijn De Weirdt 
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################
#######################################################################
#
# pro_software_component_network
# Component to configure network settings 
#
#######################################################################

unique template components/network/config;

include components/network/schema;

# Package to install.
"/software/packages"=pkg_repl("ncm-network","0.2.5-1","noarch");

# standard component settings
"/software/components/network/dependencies/pre" = list("spma");
"/software/components/network/active" ?=  true ;
"/software/components/network/dispatch" ?=  true ;
"/software/components/network/register_change/0" = "/system/network";



