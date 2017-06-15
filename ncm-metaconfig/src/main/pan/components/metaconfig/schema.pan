${componentschema}

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
                error(format('metaconfig element can only have one boolean conversion enabled, got %s', SELF));
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
                error(format('metaconfig element can only have one string conversion enabled, got %s', SELF));
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
                error(format('metaconfig element can only have one list conversion enabled, got %s', SELF));
            };
            found = true;
        };
    };

    true;
};

type caf_service_action = string with match(SELF, '^(restart|reload|stop_sleep_start)$');

type ${project.artifactId}_config =  {
    @{File permissions. Defaults to 0644.}
    'mode' : long = 0644
    @{File owner. Defaults to root.}
    'owner' : string = 'root'
    @{File group. Defaults to root.}
    'group' : string = 'root'
    @{An dict with foreach daemon the CAF::Service action to take
      if the file changes.
      Even if multiple services are associated to the same daemon, each action
      for the daemon will be taken at most once.
      If multiple actions are to be taken for the same daemon, all actions
      will be taken (no attempt to optimize is made).}
    'daemons' ? caf_service_action{}
    @{Module to render the configuration file. See 'CONFIGURATION MODULES' in manpage.}
    'module' : string
    @{Extension for the file's backup.}
    'backup' ? string
    @{Text to place at start of file.
      It can be useful to include context in a configuration file, in the form of
      a comment, such as how it was generated. Most of the formats that can be
      output by this component support "comment" lines, but none of the modules that
      it uses will generate them. The preamble attribute will be written out
      verbatim, before the contents is generated. No comment character is added,
      the user must specify this as part of the preamble string.}
    'preamble' ? string
    @{A free-form structure describing the valid entries for the
      configuration file. It is recommended to define another type for each
      config file, and bind it to these contents, to get the best validation.}
    'contents' : ${project.artifactId}_extension
    @{Predefined conversions from EDG::WP4::CCM::TextRender}
    'convert' ? ${project.artifactId}_textrender_convert
} = dict();

type ${project.artifactId}_component = {
    include structure_component
    'services' : ${project.artifactId}_config{} with valid_absolute_file_paths(SELF)
};
