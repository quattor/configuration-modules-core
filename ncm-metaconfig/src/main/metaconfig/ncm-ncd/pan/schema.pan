declaration template metaconfig/ncm-ncd/schema;

include 'pan/types';
include if_exists('components/accounts/functions');

type ncm_ncd = {
    'all' ? boolean
    'allowbrokencomps' ? boolean
    'autodeps' ? boolean
    'cache_root' ? string
    'check-noquattor' ? boolean
    'chroot' ? string
    'configure' ? string
    'facility' ? string
    'forcelock' ? boolean
    'ignore-errors-from-dependencies' ? boolean
    'ignorelock' ? boolean
    'include' ? string[]
    'log_group_readable' ? string with if (path_exists('/software/components/accounts')) {is_user_or_group('group', SELF)} else {true}
    'log_world_readable' ? boolean
    'logdir' ? string
    'logpid' ? boolean
    'multilog' ? boolean
    'noaction' ? boolean
    'nodeps' ? boolean
    'post-hook' ? string
    'post-hook-timeout' ? long(0..)
    'pre-hook' ? string
    'pre-hook-timeout' ? long(0..)
    'retries' ? long(0..)
    'skip' ? boolean
    'state' : string = "/var/run/quattor-components"
    'timeout' ? long(0..)
    'unconfigure' ? string
    'useprofile' ? long # TODO support negative CID (e.g. -1)?
    'verbose_logfile' ? boolean
};
