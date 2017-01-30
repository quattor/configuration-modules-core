# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/cups/schema;

include 'quattor/schema';

type component_cups_printer = {
    "server" ? string
    "protocol" ? string
    "printer" ? string
    "uri" ? string
    "delete" ? boolean
    "enable" ? boolean
    "class" ? string
    "description" ? string
    "location" ? string
    "model" ? string
    "ppd" ? string
};


type component_cups_options = {
    "AutoPurgeJobs" ? legacy_binary_affirmation_string
    "Classification" ? string
    "ClassifyOverride" ? string with match (SELF, "on|off")
    "DataDir" ? string
    "DefaultCharset" ? string
    "Encryption" ? string with match (SELF, "always|never|required|ifrequested")
    "ErrorLog" ? string
    "LogLevel" ? string with match (SELF, "debug2|debug|info|warn|error|none")
    "MaxCopies" ? long
    "MaxLogSize" ? long
    "PreserveJobHistory" ? legacy_binary_affirmation_string
    "PreserveJobFiles" ? legacy_binary_affirmation_string
    "Printcap" ? string
    "ServerAdmin" ? string
    "ServerName" ? string
};

type component_cups = {
    include structure_component
    "defaultprinter" ? string
    "nodetype" ? string with match (SELF, "client|server")
    "options" ? component_cups_options
    "printers" ? component_cups_printer{}
};

bind "/software/components/cups" = component_cups;
