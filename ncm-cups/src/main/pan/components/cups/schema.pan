################################################################################
# This is 'TPL/schema.tpl', a ncm-cups's file
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

declaration template components/cups/schema;

include {'quattor/schema'};

type component_cups_printer = {
    "name"          : string
    "server"        ? string
    "protocol"      ? string
    "printer"       ? string
    "uri"           ? string
    "delete"        ? boolean
    "enable"        ? boolean
    "class"         ? string
    "description"   ? string
    "location"      ? string
    "model"         ? string
    "ppd"           ? string
};


type component_cups_options = {
    "autopurgejobs"         ? string with match (SELF, "yes|no")
    "classification"        ? string
    "classifyoverride"      ? string with match (SELF, "on|off")
    "datadir"               ? string
    "defaultcharset"        ? string
    "encryption"            ? string with match (SELF,"always|never|required|ifrequested")
    "errorlog"              ? string
    "loglevel"              ? string with match (SELF,"debug2|debug|info|warn|error|none")
    "maxcopies"             ? long
    "maxlogsize"            ? long
    "preservejobhistory"    ? string with match (SELF, "yes|no")
    "preservejobfiles"      ? string with match (SELF, "yes|no")
    "printcap"              ? string
    "serveradmin"           ? string
    "servername"            ? string
};

type component_cups = {
    include structure_component
    "defaultprinter"    ? string
    "nodetype"          ? string with match (SELF,"client|server")
    "options"           ? component_cups_options
    "printers"          ? component_cups_printer[]
};

bind "/software/components/cups" = component_cups;
