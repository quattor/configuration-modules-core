declaration template metaconfig/ncm-ncd/schema;

include 'pan/types';

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
    'logdir' ? string
    'multilog' ? boolean
    'noaction' ? boolean
    'nodeps' ? boolean
    'post-hook' ? string
    'post-hook-timeout' ? long(0..)
    'pre-hook' ? string
    'pre-hook-timeout' ?  long(0..)
    'retries' ? long(0..)
    'skip' ? boolean
    'state' : string = "/var/run/quattor-components"
    'timeout' ? long(0..)
    'unconfigure' ? string
    'useprofile' ? long # TODO support negative CID (e.g. -1)?
};
