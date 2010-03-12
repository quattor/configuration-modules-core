################################################################################
# This is 'TPL/schema.tpl', a ncm-cups's file
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

declaration template components/cups/schema;

include {'quattor/schema'};

type component_cups_printer = {
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
    "AutoPurgeJobs"         ? string with match (SELF, "yes|no")
    "Classification"        ? string
    "ClassifyOverride"      ? string with match (SELF, "on|off")
    "DataDir"               ? string
    "DefaultCharset"        ? string
    "Encryption"            ? string with match (SELF,"always|never|required|ifrequested")
    "ErrorLog"              ? string
    "LogLevel"              ? string with match (SELF,"debug2|debug|info|warn|error|none")
    "MaxCopies"             ? long
    "MaxLogSize"            ? long
    "PreserveJobHistory"    ? string with match (SELF, "yes|no")
    "PreserveJobFiles"      ? string with match (SELF, "yes|no")
    "Printcap"              ? string
    "ServerAdmin"           ? string
    "ServerName"            ? string
};

type component_cups = {
    include structure_component
    "defaultprinter"    ? string
    "nodetype"          ? string with match (SELF,"client|server")
    "options"           ? component_cups_options
    "printers"          ? component_cups_printer{}
};

bind "/software/components/cups" = component_cups;
