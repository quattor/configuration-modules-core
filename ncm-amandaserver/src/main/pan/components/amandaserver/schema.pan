# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/amandaserver/schema;

include 'quattor/schema';

# Convenience type definitions

# Type columnspec (comma separated  list  of triples.
# Each triple consists of three parts which are separated by a equal sign (’=’) and a colon (’:’)
type columnspec = {
    "name" : string with match (SELF, "Compress|Disk|DumpRate|DumpTime|HostName|LevelOrigKB|OutKB|TapeRate|TapeTime")
    "space" : long
    "width" : long
};

type backupstring = string with exists(
    "/software/components/amandaserver/backups/" + SELF
) || error ("No backups with name " + SELF);

type tapetypestring = string with exists(
    "/software/components/amandaserver/backups/config/tapetypes/" + SELF
) || error ("No tapetype with name " + SELF);

type dumptypestring = string with exists(
    "/software/components/amandaserver/backups/config/dumptypes/" + SELF
) || error ("No dumptype with name " + SELF);

type interfacestring = string with exists(
    "/software/components/amandaserver/backups/config/interfaces/" + SELF
) || error ("No interfaces with name " + SELF);

type booleanstring = string with match(
    SELF,
    '^(yes|y|true|t|on|no|n|false|f|off)$'
);

type sizestring = string with match(
    SELF,
    '^(\-*\d+\s+(?i)(b|byte|bytes|k|kb|kbyte|kbytes|kilobyte|kilobytes|m|mb|meg|mbyte|mbytes|megabyte|megabytes|g|gb|gbyte|gbytes|gigabyte|gigabytes))$'
);

type speedstring = string with match(
    SELF,
    '^(\-*\d+\s+(?i)(bps|kps|kbps|mps mbps))$'
);

# General options
type structure_amandaserver_general = {
    "org" ? string
    "mailto" ? string
    "dumpcycle" ? long # In days
    "runspercycle" ? long
    "tapecycle" ? long # Number of tapes
    "dumpuser" ? string
    "printer" ? string
    "tapedev" ? string
    "rawtapedev" ? string
    "tpchanger" ? string
    "changerdev" ? string
    "changerfile" ? string
    "runtapes" ? long
    "maxdumpsize" ? sizestring
    "taperalgo" ? string with match (SELF, "first|firstfit|largest|largestfit|smallest|last")
    "labelstr" ? string
    "tapetype" ? string # deberia ser tapestring pero no se como
    "ctimeout" ? long # In seconds
    "dtimeout" ? long # In seconds
    "etimeout" ? long  # In seconds
    "inparallel" ? long
    "netusage" ? speedstring
    "dumporder" ? string with match (SELF, "^[s|S|t|T|b|B]+$")
    "maxdumps" ? long
    "bumpsize" ? sizestring
    "bumpmult" ? double
    "bumpdays" ? long
    "disklist" ? string
    "infofile" ? string
    "logdir" ? string
    "indexdir" ? string
    "tapelist" ? string
    "tapebufs" ? long
    "reserve" ? number
    "autoflush" ? booleanstring
    "amrecover_do_fsf" ? booleanstring
    "amrecover_check_label" ? booleanstring
    "amrecover_changer" ? string
    "columnspec" ? columnspec[]
    "includefile" ? string
};

# Options for holdingdisks
type structure_amandaserver_holdingdisk = {
    "comment" ? string
    "directory" ? string
    "use" ? sizestring
    "chunksize" ? sizestring
};

# Options for dumptype configuration
type structure_amandaserver_dumptype_conf = {
    "auth" ? string
    "comment" ? string
    "comprate" ? double[]
    "compress" ? string with match (SELF, '^((client|server|none)( \w+)?)$')
    "dumpcycle" ? long # In days
    "exclude" ? string with match (SELF, '^((list|file)( .+)?)$')
    "holdingdisk" ? booleanstring
    "ignore" ? booleanstring
    "include" ? string with match (SELF, '^((list|file)( .+)?)$')
    "index" ? string with match (SELF, '^(yes|y|true|t|on|no|n|false|f|off)$')
    "kencrypt" ? booleanstring
    "maxdumps" ? long
    "maxpromoteday" ? long
    "priority" ? string
    "program" ? string
    "record" ? booleanstring
    "skip-full" ? booleanstring
    "skip-incr" ? booleanstring
    "starttime" ? long # Entered as hh*100+mm
    "strategy" ? string with match (SELF, "standard|nofull|noinc|skip")
    "inc_dumptypes" ? string[] # deberia de ser dumptypestring[]
};

# Options for dumptype
type structure_amandaserver_dumptype = {
    "dumptype_name" : string
    "dumptype_conf" : structure_amandaserver_dumptype_conf
};

# Options for tapetype configuration
type structure_amandaserver_tapetype_conf = {
    "comment" ? string
    "filemark" ? sizestring
    "length" ? sizestring
    "block-size" ? sizestring
    "file-pad" ? booleanstring
    "speed" ? speedstring
    "lbl-templ" ? string
    "inc_tapetypes" ? string[] # deberia ser tapetypestring[]
};

# Options for tapetype
type structure_amandaserver_tapetype = {
    "tapetype_name" : string
    "tapetype_conf" : structure_amandaserver_tapetype_conf
};

# Options for interface configuration
type structure_amandaserver_interface_conf = {
    "comment" ? string
    "use" ? speedstring
    "inc_interfaces" ? string[] # deberia ser interfacestring[]
};

# Options for interface
type structure_amandaserver_interface = {
    "interface_name" : string
    "interface_conf" : structure_amandaserver_interface_conf
};
# The full definition for the config file
type structure_amandaserver_config = {
    "general_options" : structure_amandaserver_general
    "holdingdisks" : structure_amandaserver_holdingdisk{}
    "tapetypes" : structure_amandaserver_tapetype[]
    "dumptypes" : structure_amandaserver_dumptype[]
    "interfaces" : structure_amandaserver_interface[]
};

# Definition for a disk
type structure_amandaserver_disk = {
    "hostname" : string
    "diskname" : string
    "dumptype" : string # deberia ser dumptypestring
};

# The full definition for the component backup
type structure_amandaserver_backup = {
    "config" : structure_amandaserver_config
    "disklist" : structure_amandaserver_disk[]
};

# Definition for the component amandahosts entries
type structure_amandaserver_amandahost = {
    "domain" : string
    "user" : string
};

# The full definition for the component
type structure_component_amandaserver = {
    include structure_component
    "backups" : structure_amandaserver_backup{}
    "amandahosts" : structure_amandaserver_amandahost[]
};

bind "/software/components/amandaserver" = structure_component_amandaserver;
