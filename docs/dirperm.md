### NAME

dirperm: permissions and file/directory creation NCM component

### DESCRIPTION

Object to set permissions and ownership of files and directories.
Will create directories if they do not exist (with the proper
permissions).  Useful, e.g., to give every pool-user a ".globus"
directory in its `$HOME`, or to create a bunch of home directories for
poolaccounts on a non-CE machine.

If the list initdir is set, then files in those directories will be
copied to the created directory.  They will be given the same
ownership as the directory.

When creating a file, all of the parent directories must already
exist.

### RESOURCES

#### `/software/components/dirperm/paths`

A list of files/directories to manage with this component.
Each entry in the list must be of the `structure_dirperm_entry` type which has the following fields:

- `path`

    String representing full path of configured file/directory.

- `owner`

    String representing ownership, of form `user` or `user:group`.

- `perm`

    String containing octal permissions to enforce.

- `type`

    String, either `'d'` for directory or `'f'` for file.

- `initdir`

    Optional list of strings representing full paths to directories.

    If the target is a directory, this can be used to prepopulate the directory by copying files from multiple sources.
    This is particularly useful for home directories.

### EXAMPLES

    "/software/components/dirperm/paths" = list(
        nlist(
            "path",    "/export/home/alice002/.globus",
            "owner",   "alice002:alice",
            "perm",    "0700",
            "type",    "d",
            "initdir", list("/etc/skel")
        ),
     );
