################################################################################
# This is 'TPL/schema.tpl', a ncm-openldap's file
################################################################################
#
# VERSION:    1.0.0-1, 02/02/10 15:50
# AUTHOR:     Daniel Jouvenot <jouvenot@lal.in2p3.fr>
# MAINTAINER: Guillaume Philippon <philippo@lal.in2p3.fr>
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/openldap/schema;

include { 'quattor/schema' };

type component_openldap = {
	include structure_component
	'conf_file'		?	string
	'include_schema'	: string[]
	'loglevel' 		? long(0..)
	'pidfile' 		? string
	'argsfile' 		? string
	'database'		: string
	'suffix'		: string
	'rootdn'		: string
	'rootpw'		: string
	'directory'		: string
	'index'			? string[]
};

bind '/software/components/openldap' = component_openldap;

