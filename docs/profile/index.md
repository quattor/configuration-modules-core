### NAME

profile: Create profile scripts defining environment variables and paths.

### DESCRIPTION

The _profile_ component creates two scripts (sh and csh flavors, respectively .sh and .csh extension) in
the given configuration directory.  This directory by default is
`/etc/profile.d`.  These scripts contain environment variable and path
definitions.

Note that the only guarantee with respect to order is that all the
environment variables will be defined before the paths.

### RESOURCES

- configDir (/etc/profile.d)

    The directory which contains the generated files.  This directory will
    be created if necessary.

- configName (env)

    The base name of the default profile.d file to create.  This gives some
    flexibility on the order in which the profile script will be executed.
    (Normally executed in alphabetical order.)  The full filename will
    have ".\[c\]sh" appended to it. 

- env 

    A hash containing the environment variables to define in the default script. The environment variable name is the key and the
    value is a string.

- path

    A structure defining (optionally) paths to define in default script. It may contain prepend, append, and value
    elements.  Each element is a list of strings. 

    The prepended values will be prepended and the appended values
    appended to the current value of the path.  If the value is specified,
    then the current path will be overwritten with the given value (and
    the prepended and appended values applied to it).

    Only the first occurrence of a particular path will be kept in the
    final definition.  Note that if the current path is used, there may
    still be some duplicates coming from the current definition. 

- scripts

    A nlist describing the contents of scripts other than the default one. Key is the script base name
    (.sh or .csh extension appended in actual script name) and may be either a relative name
    in which case the script is created in configDir or an absolute name (in this case it must be escaped).

    Value is a nlist that may contains 'env' and 'path' properties (as in the default script) plus the properties described
    below.

    - flavors : list of string (required)

        Defines a list of script flavors to build. Valid values are 'csh' and 'sh'.

        Default : csh,sh

    - flavorSuffix : boolean (required)

        This property indicates whether to add a .sh or .csh suffix to the script path. If false, only one flavor must be 
        specified.

        Default : true

### FUNCTIONS

#### component\_profile\_add\_env()

This functions adds an environment variable to a script. It returns component profile configuration. There are 2
calling formats :

    'software/components/profile' = component_profile_add_env(script_name, env_name, env_value);
    'software/components/profile' = component_profile_add_env(script_name, env_list);

In the second form, 'env\_list' is a list of nlists. Each nlist must be a pair of environment variable name and value.

#### component\_profile\_add\_path()

This functions adds a path variable to a script. It returns component profile configuration. The calling format is:

    'software/components/profile' = component_profile_add_path(script_name, path_name, path_value [, value_type]);

'value\_type' is an optional argument indicating the kind of value. May be:

- value: this is the base value for the path and replaces an existing value
- prepend: this value is prepended to an existing value, if any
- append: this value is appended to an existing value, if any

### EXAMPLE

    '/software/components/profile/configDir' = "/etc/profile.d";
    '/software/components/profile/configDir' = "z_env";
    '/software/components/profile/env/VARIABLE_ONE' = "VALUE";
    '/software/components/profile/path/PATH/prepend' = list("alpha","beta","gamma");
