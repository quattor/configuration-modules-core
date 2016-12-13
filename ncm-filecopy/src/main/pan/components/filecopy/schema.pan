# ${license-info}
# ${developer-info}
# ${author-info}
declaration template components/filecopy/schema;

include 'quattor/schema';

function component_filecopy_valid = {
    function_name = 'component_filecopy_valid';
    if ( ARGC != 1 ) {
        error(function_name+': this function requires 1 argument');
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
    'config' ? string      # Contents embedded in configuration
    'source' ? string      # source file
    'restart' ? string
    'perms' ? string with match(SELF, '^[02-6]?[0-7]{3,3}$')
    'owner' ? string
    'group' ? string
    'no_utf8' ? boolean
    'forceRestart' : boolean = false
    'backup' : boolean = true
} with component_filecopy_valid(SELF);


type component_filecopy = {
    include structure_component
    'services' ? structure_filecopy{} with valid_absolute_file_paths(SELF)
    'forceRestart' : boolean = false
};

bind '/software/components/filecopy' = component_filecopy;
