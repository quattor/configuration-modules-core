declaration template metaconfig/mlocate/schema;

include 'pan/types';

@documentation{
Prunename can not contain slashes.
}
type prunename = string with match(SELF, '^((?!/).)*$');

@documentation{
Override the default config file
}
type config_updatedb = {
    @{A list of file system types which should not be scanned by updatedb.}
    'prunefs' ? string[]
    @{A list of directory names (without paths) which should not be scanned by updatedb.}
    'prunenames' ? prunename[]
    @{A list of path names of directories which should not be scanned by updatedb.}
    'prunepaths' ? absolute_file_path[]
    @{If prune_bind_mounts is set to true, bind mounts are not scanned by updatedb.}
    'prune_bind_mounts' ? boolean
};
