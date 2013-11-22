################################################################################
# This is 'TPL/schema.tpl', a ncm-spma's file
################################################################################
#
# VERSION:    1.0.0, 08/10/13 13:43
# AUTHOR:     Mark R. Bannister <Mark.Bannister@morganstanley.com>
# MAINTAINER: Mark R. Bannister <Mark.Bannister@morganstanley.com>
# LICENSE:    http://cern.ch/eu-datagrid/license.html
#
################################################################################
# Coding style: emulate <TAB> characters with 4 spaces, thanks!
################################################################################

declaration template components/spma/ips/schema;

type component_spma_ips_type = {
    "bename"        ? string         # BE name to use with IPS commands
    "rejectidr"     : boolean = true # Reject Solaris IDRs on upgrade?
    "freeze"        : boolean = true # Ignore frozen packages?
};

type component_spma_ips = {
    "ips"           ? component_spma_ips_type
};
