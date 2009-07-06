# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/filecopy/schema;

include { 'quattor/schema' };

type structure_filecopy = {
    'config'      : string
    'restart'     ? string
    'perms'       ? string with match(SELF, '^[02-6]?[0-7]{3,3}$')
    'owner'       ? string
    'group'       ? string
    'no_utf8'     ? boolean
    'forceRestart' : boolean = false
    'backup'      ? boolean = true
};


type component_filecopy = {
    include structure_component
    'services'    ? structure_filecopy{}
    'forceRestart' : boolean = false
};

bind '/software/components/filecopy' = component_filecopy;


