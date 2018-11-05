${componentschema}
include 'quattor/types/component';

type structure_symlink_replace_option_entry = {
    @{use when renaming a given object type or to enable replacement for a specific object type.}
    "all" ? string
    @{means any directory.}
    "dir" ? string
    @{means an empty directory only.}
    "dirempty" ? string
    "file" ? string
    "link" ? string
    @{use when renaming a given object type or to prevent replacement for a specific object type.}
    "none" ? string
};

type structure_symlink_entry = {
    @{symbolic link name (path).}
    "name" : string
    @{The target path can be built using a command output with the command string
    (can include valid command options) to execute between a pair of '@@' or a
    contextual variable (variables are defined in "/software/components/symlinks/context").
    Unless the shell command between '@@' must be reevaluated for each link, it is
    better to associate the shell command with a contextual variable and use the
    variable in the target definition, as a contextual variable is evaluated once (global).}
    "target" : string
    @{Check that the target exists when creating it or check that the symlink
    name exists when deleting it.}
    "exists" ? boolean
    @{Delete the symlink (not its target) rather than creating it. "target" can be
    ommitted in this case and if present, it is not checked to be this value before
    deletion. If "exists" is true, raise an error, if the link is not found else
    just silently ignore it. }
    "delete" ? boolean
    @{Option used to specify the action to take when an object with the same
    name as the symlink already exists, depending on the object type.
    Possible actions are: do not define the symlink, replace the
    object by the symlink or define the symlink after renaming the object.}
    "replace" ? structure_symlink_replace_option_entry
};

type structure_symlink_context_entry = {
    "name" : string
    "value" : string
};

type structure_symlink_option_entry = {
    @{Action applying to the object type. Can be "yes" (replacement of the object
    by the symlink allowed), "no" (replacement of the object by the symlink
    disabled) or any other string. In this latter case, replacement of the object
    by the symlink is enabled after renaming the object by appending the string
    to its name.}
    "exists" ? boolean
    @{"replace" option allows a lot of flexibility in specifying what should
    be done in case of conflict with an existing object.}
    "replace" ? structure_symlink_replace_option_entry
};

type symlink_component = {
    include structure_component
    @{A list of symbolic links to create or delete.}
    "links" ? structure_symlink_entry[]
    @{A list of contextual variables to use in target definitions. Each entry is
    a key/value pair with the variable name as the key. The value can contain
    a command output, as link target definition: see "target" description above.
    Contextual variables are global. They are evaluated once, before starting to define
    symlinks. }
    "context" ? structure_symlink_context_entry[]
    @{A list of global options used as default for all links creation/deletion.
    Supported options are the same as options supported in the link definition
    (see above), with the exception of "delete".}
    "options" ? structure_symlink_option_entry
};
