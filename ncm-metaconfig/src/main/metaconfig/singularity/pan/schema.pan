declaration template metaconfig/singularity/schema;

include 'pan/types';

type singularity_absolute_path = string with {
    paths = split(':', SELF);
    if ((length(paths) > 0) && (length(paths) < 3)) {
        foreach (idx; path; paths) {
            if (!is_absolute_file_path(path)) {
                error(format("Invalid Singularity absolute path: %s", path));
            };
        };
        return(true);
    };
    error(format("Wrong absolute path Singularity mapping: %s", SELF));
};

type singularity_allow_ns = {
    @{Should we allow users to request the PID namespace?}
    'ns' : boolean = true
} = dict();

type singularity_allow = {
    @{Should we allow users to utilize the setuid binary for launching singularity?
    The majority of features require this to be set to yes, but newer Fedora and
    Ubuntu kernels can provide limited functionality in unprivileged mode}
    'setuid' : boolean = true
    'pid' : singularity_allow_ns
} = dict();

type singularity_user = {
    @{If /etc/passwd exists within the container, this will automatically append
    an entry for the calling user}
    'passwd' : boolean = true
    @{If /etc/group exists within the container, this will automatically append
    an entry for the calling user}
    'group' : boolean = true
    @{If there is a bind point within the container, use the host's /etc/resolv.conf}
    'resolv_conf' : boolean = true
} = dict();

type singularity_overlay = {
    @{Enabling this option will make it possible to specify bind paths to locations
    that do not currently exist within the container. Some limitations still exist
    when running in completely non-privileged mode. (note: this option is only
    supported on hosts that support overlay file systems)}
    'overlay' : boolean = false
} = dict();

type singularity_mount = {
    @{Should we automatically bind mount /proc within the container?}
    'proc' : boolean = true
    @{Should we automatically bind mount /sys within the container?}
    'sys' : boolean = true
    @{Should we automatically bind mount /dev within the container? If you select
    minimal, and if overlay is enabled, then Singularity will attempt to create
    the following devices inside the container: null, zero, random and urandom}
    'dev' : boolean = true
    @{Should we automatically determine the calling user's home directory and
    attempt to mount it's base path into the container? If the --contain option
    is used, the home directory will be created within the session directory or
    can be overridden with the SINGULARITY_HOME or SINGULARITY_WORKDIR
    environment variables (or their corresponding command line options)}
    'home' : boolean = true
    @{Should we automatically bind mount /tmp and /var/tmp into the container? If
    the --contain option is used, both tmp locations will be created in the
    session directory or can be specified via the  SINGULARITY_WORKDIR
    environment variable (or the --workingdir command line option)}
    'tmp' : boolean = true
    @{Probe for all mounted file systems that are mounted on the host, and bind
    those into the container?}
    'hostfs' : boolean = false
    @{Should we automatically propagate file-system changes from the host?
    This should be set to 'true' when autofs mounts in the system should
    show up in the container}
    'slave' : boolean = true
} = dict();

type singularity_bind_path = {
    @{Define a list of files/directories that should be made available from within
    the container. The file or directory must exist within the container on
    which to attach to. you can specify a different source and destination
    path (respectively) with a colon; otherwise source and dest are the same}
    'path' ? singularity_absolute_path[]
};

type singularity_bind_user_control = {
    @{Allow users to influence and/or define bind points at runtime? This will allow
    users to specify bind points, scratch and tmp locations. (note: User bind
    control is only allowed if the host also supports PR_SET_NO_NEW_PRIVS)}
    'control' : boolean = true
} = dict();

type singularity_bind_user = {
    'bind' : singularity_bind_user_control
} = dict();

type singularity_container = {
    @{This path specifies the location to use for mounting the container, overlays
    and other necessary file systems for the container. Note, this location
    absolutely must be local on this host}
    'dir' : absolute_file_path = '/var/singularity/mnt'
} = dict();

type singularity_sessiondir_max_size = {
    @{This specifies how large the default sessiondir should be (in MB) and it will
    only affect users who use the "--contain" options and do not also specify a
    location to do default read/writes to (e.g. "--workdir" or "--home")}
    'size' : long(1..) = 16
} = dict();

type singularity_sessiondir = {
    @{This specifies the prefix for the session directory. Appended to this string
    is an identification string unique to each user and container. Note, this
    location absolutely must be local on this host. If the default location of
    /tmp/ does not work for your system, /var/singularity/sessions maybe a
    better option}
    'prefix' ? absolute_file_path
    'max' : singularity_sessiondir_max_size
} = dict();

type singularity_max_loop_devices = {
    @{Set the maximum number of loop devices that Singularity should ever attempt
    to utilize}
    'devices' : long(1..) = 256
} = dict();

type singularity_max_loop = {
    'loop' : singularity_max_loop_devices
} = dict();

type singularity_limit_container = {
    @{Only allow containers to be used that are owned by a given user. If this
    configuration is undefined (commented or set to NULL), all containers are
    allowed to be used. This feature only applies when Singularity is running in
    SUID mode and the user is non-root}
    'owners' ? string[]
    @{Only allow containers to be used that are located within an allowed path
    prefix. If this configuration is undefined (commented or set to NULL),
    containers will be allowed to run from anywhere on the file system. This
    feature only applies when Singularity is running in SUID mode and the user is
    non-root}
    'paths' ? singularity_absolute_path[]
} = dict();

type singularity_limit = {
    'container' ? singularity_limit_container
} = dict();

@documentation{
singularity.conf settings
This is the global configuration file for Singularity. This file controls
what the container is allowed to do on a particular host, and as a result
this file must be owned by root.
}
type service_singularity = {
    'allow' : singularity_allow
    'config' : singularity_user
    'enable' : singularity_overlay
    'mount' : singularity_mount
    'bind' ? singularity_bind_path
    'user' : singularity_bind_user
    'container' : singularity_container
    'sessiondir' : singularity_sessiondir
    'max' : singularity_max_loop
    'limit' ? singularity_limit
};
