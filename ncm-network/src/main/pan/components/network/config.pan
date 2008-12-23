################################################################################
# This is 'TPL/config.tpl', a ncm-network's file
################################################################################
#
# VERSION:    0.2.6-1, 09/12/08 11:19
# AUTHOR:     Stijn De Weirdt 
# MAINTAINER: Stijn De Weirdt 
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################
#######################################################################
#
# Component to configure network settings 
#
#######################################################################

unique template components/network/config;

include { 'components/network/schema' };

# Package to install.
"/software/packages"=pkg_repl("ncm-network","0.2.6-1","noarch");

'/software/components/network/version' ?= '0.2.6';

# standard component settings
"/software/components/network/dependencies/pre" = list("spma");
"/software/components/network/register_change/0" = "/system/network";



