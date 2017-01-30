# ${license-info}
# ${developer-info}
# ${author-info}
declaration template components/profile/functions;

# Function to add an environment variable to a script
#    'software/components/profile' = component_profile_add_env(script_name, env_name, env_value);
# or
#    'software/components/profile' = component_profile_add_env(script_name, env_list);
#
# In the second form, env_list is a dict of string : key is the variable name, value is the variable value (may be
# a string, long, boolean or list of string).
#
# 'script_name' is parsed and if it ends with extension '.sh' or '.csh', extension is removed and
# script flavor is set accordingly.
#
# If the variable already exists, its value is replaced. A variable value may be a string, boolean, long or a list
# of string. If necessary, they are converted to string. A list is converted into a colon separated string.
#

function component_profile_add_env = {
    function_name = 'component_profile_add_env';
    if ( (ARGC < 2) || (ARGC > 3) ) {
        error(function_name+': invalid number of arguments. Must be 2 or 3.');
    };
    if ( ARGC == 2 ) {
        if ( is_dict(ARGV[1]) ) {
            env_list = ARGV[1];
        } else {
            error(function_name+': with 2 arguments, second argument must be a dict.');
        };
    } else {
        env_list = dict(ARGV[1], ARGV[2]);
    };


    toks = matches(ARGV[0], '^(.*)\.(c?sh)$');
    if ( length(toks) == 3 ) {
        script_name = escape(toks[1]);
        SELF['scripts'][script_name]['flavors'] = list(toks[2]);
    } else {
        script_name = escape(ARGV[0]);
    };


    foreach (var_name;var_value;env_list) {
        var_value_str = '';
        if ( is_string(var_value) ) {
            var_value_str = var_value;
        } else if ( is_long(var_value) || is_boolean(var_value) ) {
            var_value_str = to_string(var_value);
        } else if ( is_list(var_value) ) {
            foreach (j;val;var_value) {
                if ( !is_string(val) ) {
                    error(function_name+': variable '+var_name+' value is a list whose elements are not string');
                };
                if ( length(var_value_str) > 0 ) {
                    var_value_str = var_value_str + ':';
                };
                var_value_str = var_value_str + val;
            };
        } else {
            error(function_name+': variable '+var_name+' value has an unsupported type (must be string, long, boolean or list of string');
        };
        SELF['scripts'][script_name]['env'][var_name] = var_value_str;
    };

    return(SELF);
};

# Function to add a path variable to a script
#    'software/components/profile' = component_profile_add_path(script_name, path_name, path_value [, value_type]);
#
# 'script_name' is parsed and if it ends with extension '.sh' or '.csh', extension is removed and
# script flavor is set accordingly.
#
# 'path_name' is the name of the path variable.
#
# 'path_value' must be a string or a list of string.
#
# 'value_type' is an optional argument indicating the kind of value. May be:
#     - value: this is the base value for the path and replaces an existing value
#     - prepend: this value is prepending to an existing value, if any
#     - append: this value is appended to an existing value, if any
#
# This function may be called several times for the same path variable with different value_type.
# If the path variable element already exists, its value is updated.

function component_profile_add_path = {
    function_name = 'component_profile_add_path';
    if ( (ARGC < 3) || (ARGC > 4) ) {
            error(function_name+': invalid number of arguments. Must be 3 or 4.');
    };
    if ( ARGC == 4 ) {
        value_type = ARGV[3];
    } else {
        value_type = 'value';
    };
    if ( !match(value_type, 'value|append|prepend') ) {
        error("'value_type' argument must be 'value', 'prepend' or 'append'");
    };


    toks = matches(ARGV[0], '^(.*)\.(c?sh)$');
    if ( length(toks) == 3 ) {
        script_name = escape(toks[1]);
        SELF['scripts'][script_name]['flavors'] = list(toks[2]);
    } else {
        script_name = escape(ARGV[0]);
    };

    if ( is_string(ARGV[2]) ) {
        var_value = list(ARGV[2]);
    } else if ( is_list(ARGV[2]) ) {
        var_value = ARGV[2];
    } else {
        error(function_name+': variable '+var_name+' value has an unsupported type (must be string, or a list of string');
    };
    SELF['scripts'][script_name]['path'][ARGV[1]][value_type] = var_value;

    return(SELF);
};
