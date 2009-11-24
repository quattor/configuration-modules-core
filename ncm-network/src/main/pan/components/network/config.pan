################################################################################
# This is 'TPL/config.tpl', a ncm-network's file
################################################################################
#
# VERSION:    1.2.0-4, 14/07/09 12:24
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
"/software/packages"=pkg_repl("ncm-network","1.2.0-4","noarch");

'/software/components/network/version' ?= '1.2.0';

# standard component settings
"/software/components/network/dependencies/pre" = list("spma");
"/software/components/network/register_change/0" = "/system/network";



