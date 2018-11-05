# ${license-info}
# ${developer-info}
# ${author-info}
declaration template components/filecopy/schema;

include 'quattor/schema';

function component_filecopy_valid = {
    function_name = 'component_filecopy_valid';
    if ( ARGC != 1 ) {
        error(function_name + ': this function requires 1 argument');
    };

    if ( !is_defined(SELF['config']) && !is_defined(SELF['source']) ) {
        error("ncm-filecopy requires either 'config' or 'source' property to be present.");
    } else if ( is_defined(SELF['config']) && is_defined(SELF['source']) ) {
        error("ncm-filecopy: 'config' and 'source' properties are mutually exclusive.");
    };

    true;
};

# source and config are mutually exclusive, one is required.
type structure_filecopy = {
    @{The file content specified as a string.}
    'config' ? string
    @{The name of a source file already present on the machine to
    use as the content for the managed file.}
    'source' ? string
    @{A command to execute if the file is modified. It is typically used to restart a service
    but any valid command can be specified, including several commands separated by ';'.
    If not specified, the file is updated but no command is executed.
    Restart commands are executed after all files have been updated.
    If several files specify the same restart command, it is executed once.}
    'restart' ? string
    @{Permissions of the managed file. If not specified,
     the default permissions on the system will be used.}
    'perms' ? string with match(SELF, '^[02-6]?[0-7]{3,3}$')
    @{The userid of the file owner. It can also be a 'user:group' specification (like with chown).}
    'owner' ? string
    @{The group of the file owner. It is ignored if the owner is specified as 'user:group'.}
    'group' ? string
    @{By default, the file content is converted to UTF8.
    Define this property to 'true' to prevent this conversion.}
    'no_utf8' ? boolean
    @{A boolean that defines if the restart command (if any defined).
    must be executed even though the file was up-to-date (default behaviour is to execute the
    restart command only if file content, permissions or owner/group has been changed).
    Note: this attribute is ignored if the global 'forceRestart' value is true.}
    'forceRestart' : boolean = false
    @{This property specifies if an existing version of the file must be backed up
     before being updated (backup extension is '.old'). }
    'backup' : boolean = true
} with component_filecopy_valid(SELF);


type component_filecopy = {
    include structure_component
    @{This dict contains one entry by file to manage. The key is the escaped file name.
    For each file, the property described below may be specified.
    Most properties are optional (or have a default value) but either 'config'
    or 'source' MUST be specified and they are mutually exclusive.}
    'services' ? structure_filecopy{} with valid_absolute_file_paths(SELF)
    @{A boolean that defines if the restart command (if any defined) of the file(s)
    must be executed even though the files were up-to-date (default behaviour is to execute the
    restart command only if file content, permissions or owner/group has been changed).}
    'forceRestart' : boolean = false
    @{A boolean that defines if failures of restart command should be regarded as fatal or not.}
    'ignore_restart_failure' ? boolean
};

bind '/software/components/filecopy' = component_filecopy;
