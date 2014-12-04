---
layout: documentation
title: symlink
category: documentation
subcategory: components
menu: 'components.md'
---
Be sure to put a blank line before and after every formatting command

### NAME

symlink : symlink NCM component.

### DESCRIPTION

Object to create/delete symbolic links. When creating symlinks, target existence can be checked. And clobbering can be disabled.

Target definition may contain contextual variable, using syntax '{variable}'. Variables are defined globaly for all links and allow to use the same target definition for different contexts (e.g. platforms).

Target definition and contextual variable value may also contain expression interpreted as shell commands (.eg. uname). These expressions must enclosed between pair of '@@'. Unless shell command must reevaluated for each link, it is better to associate the shell command with a contextual variable and use the variable in the target definition, as a contextual variable is evaluated once (global).

### RESOURCES

#### `/software/components/symlink/links`

A list of symbolic links to create or delete.  Each entry
must be of the structure\_symlink\_entry type which has the following
fields: name, target, delete, exists, replace.

'name' is the symbolic link name, 'target' is the link target, other fields are boolean. 'delete' means delete the link rather than create. 'exists' means check the target exists when creating or check the link exists when deleting. 

'replace' is an option taking one or several of the several following suboptions : all, dir, dirempty, file, link, none. Each suboption can have the following values : 'yes', 'no', a string interpreted as a file extension used to rename the existing object with the link name. If a suboption value is empty, it is interpreted as 'yes'. If value is 'yes', replacement is enabled but existing object is not renamed, except if a default extension has been defined with 'none' or 'all' or if it is a non empty directory (renamed with a default extension).

When 'all' or 'none' suboption is specified, other suboptions can be specified too to redefine extension or to prevent replacement of a specific object type. 'dirempty' means directory is replaced only if empty. 'none=extension' can be used to establish a default backup extension without enabling replacement (as it is with 'all').

#### `/software/components/symlink/context`

A list of contextual variables to use in target definitions.  Each entry
must be of the structure\_symlink\_\_context\_entry type which has the following
fields: name, value.  Contextual variables are global.

#### `/software/components/symlink/options`

A list of global options used as default for all links creation/deletion. Supported options are the same as options supported in the link definition (see above), with the exception of 'delete'.

### EXAMPLES
 

    "/software/components/symlink/links" = 
      list(nlist(
             "name",    "/usr/bin/tcsh",
             "target",   "/bin/tcsh",
             "exists",    true
            )
      );

    "/software/components/symlink/links" = 
      list(nlist(
             "name",    "/atlas",
             "target",   "/atlas_prod/@@uname@@",
             "exist",    true
            )
      );

    "/software/components/symlink/context" = 
      list(nlist(
             "name",    "ostype",
             "value",   "@@uname@@",
            )
      );
    "/software/components/symlink/links" = 
      list(nlist(
             "name",    "/atlas",
             "target",   "/atlas_prod/{ostype}",
             "exists",    true
            )
      );

    ### Allow replacement of empty directories and links
    "/software/components/symlink/options/replace/dirempty" = ".saved"; 
    "/software/components/symlink/options/replace/link" = "yes";

    "/software/components/symlink/links" = 
      list(nlist(
             "name",    "/usr/local",
             "target",   "/lal_prod/{ostype}",
             "exists",    true
            )
      );

### DEPENDENCIES

None.

### BUGS

None known.

Michel Jouvin <>

Michel Jouvin <>

### VERSION

1.3.2

### SEE ALSO

ncm-ncd(1)
