################################################################################
# This is 'TPL/schema.tpl', a ncm-network's file
################################################################################
#
# VERSION:    1.1.0-1, 12/06/09 11:06
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

include { 'quattor/schema' };


type component_network_type = {
	include structure_component
};


bind "/software/components/network" = component_network_type;


