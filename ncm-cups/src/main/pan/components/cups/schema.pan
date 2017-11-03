${componentschema}

include 'quattor/schema';

type ${project.artifactId}_component_printer = {
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


type ${project.artifactId}_component_options = {
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
    "ServerAlias" ? string[]
    "ServerName" ? string
};

type ${project.artifactId}_component = {
    include structure_component
    "defaultprinter" ? string
    "nodetype" ? string with match (SELF, "client|server")
    "options" ? ${project.artifactId}_component_options
    "printers" ? ${project.artifactId}_component_printer{}
};

