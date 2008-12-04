################################################################################
# This is 'TPL/schema.tpl', a ncm-network's file
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
############################################################
#
# type definition components/network
#
#
#
############################################################

declaration template components/network/schema;

include quattor/schema;


type component_network_type = {
	include structure_component
};


type "/software/components/network" = component_network_type;


