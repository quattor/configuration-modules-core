# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/${project.artifactId}/schema;

include 'quattor/types/component';
include 'quattor/functions/validation';

type ${project.artifactId}_extension = extensible {};

@documentation{
    Convert value of certain types (e.g. boolean to string yes/no)
    (using the CCM::TextRender element options)
}
type ${project.artifactId}_textrender_convert = {
    @{Convert boolean to (lowercase) 'yes' and 'no'.}
    'yesno' ? boolean
    @{Convert boolean to (uppercase) 'YES' and 'NO'.}
    'YESNO' ? boolean
    @{Convert boolean to (lowercase) 'true' and 'false'.}
    'truefalse' ? boolean
    @{Convert boolean to (uppercase) 'TRUE' and 'FALSE'.}
    'TRUEFALSE' ? boolean
    @{Convert string to doublequoted string.}
    'doublequote' ? boolean
    @{Convert string to singlequoted string.}
    'singlequote' ? boolean
    @{Convert list to comma-separated string}
    'joincomma' ? boolean
    @{Convert list to space-separated string}
    'joinspace' ? boolean
} with {
    # Only one boolean conversion can be true
    boolean_conversion = list('yesno', 'YESNO', 'truefalse', 'TRUEFALSE');
    found = false;
    foreach (idx; name; boolean_conversion) {
        if(exists(SELF[name]) && SELF[name]) {
            if(found) {
                error('metaconfig element can only have one boolean conversion enabled, got '+to_string(SELF));
            };
            found = true;
        };
    };

    # Only one string conversion can be true
    string_conversion = list('singlequote', 'doublequote');
    found = false;
    foreach (idx; name; string_conversion) {
        if(exists(SELF[name]) && SELF[name]) {
            if(found) {
                error('metaconfig element can only have one string conversion enabled, got '+to_string(SELF));
            };
            found = true;
        };
    };

    # Only one list conversion can be true
    list_conversion = list('joincomma', 'joinspace');
    found = false;
    foreach (idx; name; list_conversion) {
        if(exists(SELF[name]) && SELF[name]) {
            if(found) {
                error('metaconfig element can only have one list conversion enabled, got '+to_string(SELF));
            };
            found = true;
        };
    };

    true;
};

type caf_service_action = string with match(SELF, '^(restart|reload|stop_sleep_start)$');

type ${project.artifactId}_config =  {
    'mode' : long = 0644
    'owner' : string = 'root'
    'group' : string = 'root'
    'daemons' ? caf_service_action{}
    'module' : string
    'backup' ? string
    'preamble' ? string
    'contents' : ${project.artifactId}_extension
    'convert' ? ${project.artifactId}_textrender_convert
} = nlist();

type ${project.artifactId}_component = {
    include structure_component
    'services' : ${project.artifactId}_config{} with valid_absolute_file_paths(SELF)
};
