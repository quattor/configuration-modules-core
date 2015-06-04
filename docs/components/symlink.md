### NAME

symlink : symlink NCM component.

### DESCRIPTION

Object to create/delete symbolic links. When creating symlinks, target existence can be checked. And clobbering can be disabled. Also, target definition can be simplified by
the use of contextual variables and command outputs.

### RESOURCES

#### `/software/components/symlink/links`

A list of symbolic links to create or delete.  Each entry
must be of the structure\_symlink\_entry type which has the following
fields:

- `name`: symbolic link name (path).
- `target`: link target path. The target path can be built using a command output with the command string (can include valid command options)
to execute between a pair of `@@` or a contextual variable using the syntax
`{variable}` (variables are defined in `/software/components/symlinks/context`). Unless the shell command between `@@` must be reevaluated for each link, it is better
to associate the shell command
with a contextual variable and use the variable in the target definition, as a contextual variable is evaluated once (global).
- `delete`: (boolean) delete the symlink (not its target) rather than creating it. `target` can be ommitted in this case and if present, it is not checked to be this value before
deletion. If `exists` is true, raise an error, if the link is not found else just silently ignore it.
- `exists`: (boolean) check that the target exists when creating it or check that the symlink name exists when deleting it.
- `replace`: (nlist) option used to specify the action to take when an object with the same name as the symlink already exists, depending on the object type.
Possible actions are: do not define the symlink, replace the
object by the symlink or define the symlink after renaming the object. The nlist keys and values can be:
    - key: the existing object type. Valid values are: `all`, `dir`, `dirempty`, `file`, `link`, `none`.  `dirempty` means an empty directory only, `dir` means any directory.
    `all` and `none` are mutually exclusive but can be combined with other object types to define the extension to use when renaming a given object type or to prevent/enable replacement for a specific object type.
    - value: action applying to the object type. Can be `yes` (replacement of the object by the symlink allowed), `no` (replacement of the object by the symlink disabled) or any other
    string. In this latter case, replacement of the object by the symlink is enabled after renaming the object by appending the string to its name. The value can also be empty: see
    below. Note that non empty directories are **always** renamed before defining the symlink (a default extension, `.ncm-symlink_saved`, is used).

`replace` option allows a lot of flexibility in specifying what should be done in case of conflict with an existing object. It implements the following advanced features:

- `none=extension` can be used to establish a default rename extension without actually enabling replacement for a particular type. This extension
will be used with object types for which replacement is enabled with `yes` rather than an extension.
- Action can be empty. If a default rename extension was defined with `none=extension`, the object will be renamed before defining the symlink. Else it is interpreted as `yes`.

#### `/software/components/symlink/context`

A list of contextual variables to use in target definitions.  Each entry is a key/value pair with the variable name
as the key. The value can contain a command output, as link target definition: see `target` description above.
Contextual variables are global. They are evaluated once, before starting to define
symlinks.

#### `/software/components/symlink/options`

A list of global options used as default for all links creation/deletion. Supported options are the same as options supported in the link definition (see above),
with the exception of `delete`.

### EXAMPLES

       ### Define global variable osdir so that it can be use to define symlink targets
       "/software/components/symlink/context" = {
         append(nlist(
                  "name",    "ostype",
                  "value",   "@@uname@@",
         ));
       };

       ### Various symlink definition examples
       "/software/components/symlink/links" = {

         ### Define `/usr/bin/tcsh` only if `/bin/tcsh` exists
         append(nlist(
                 "name",    "/usr/bin/tcsh",
                 "target",   "/bin/tcsh",
                 "exists",    true
         ));

         ### Define `/atlas` with a target actual value including C<uname> command output
         append(nlist(
                 "name",    "/atlas",
                 "target",   "/atlas_prod/@@uname@@",
                 "exist",    true
         ));

         ### Define `/lhcb` with a target actual value including a contextual variable.
         ### The contextual variable can be defined before or later in the configuration.
         append(nlist(
                 "name",    "/lhcb",
                 "target",   "/lhcb_prod/{ostype}",
                 "exists",    true
         ));

         ### Define `/usr/local` as a symlink only if the `/lal/prod/{ostype}` exists
         append(nlist(
                  "name",    "/usr/local",
                  "target",   "/lal_prod/{ostype}",
                  "exists",    true
         ));

         ### Define symlink `/etc/alpine/conf`, replacing an existing
         ### file by the symlink without renaming it
         append(nlist(
                  "name", "/etc/alpine/pine.conf",
                  "target", "/lal/gen/etc/pine.conf",
                  "replace",  nlist("all", "yes"),
         ));

         ### Define symlink `/etc/pine.conf`, replacing an existing file or symlink
         ### by the new symlink, after renaming it using extension .saved
         append(nlist(
                  "name", "/etc/pine.conf",
                  "target", "/lal/gen/etc/pine.conf",
                  "replace",  nlist("none", ".saved", "file", "yes", "link", "yes"),
         ));

         ### Define `/htdocs` as a link only if `/htdocs` doesn't exist or already
         ### exists as a symlink (actual target not checked)
         append(nlist(
                  "name", "/htdocs",
                  "target", HTTPD_HTDOCS_DIR,
                  "replace",  nlist("all","no","link", "yes")
         ));
       ### End of symlink definitions
       };

       ### Define options to enable replacement of empty directories and links,
       ### with empty directories renamed adding C<.saved> to their name before
       ### defining the symlink.
       "/software/components/symlink/options/replace/dirempty" = ".saved";
       "/software/components/symlink/options/replace/link" = "yes";


