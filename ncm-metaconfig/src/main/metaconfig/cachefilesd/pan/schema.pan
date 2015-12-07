declaration template metaconfig/cachefilesd/schema;

include 'pan/types';

type cachefilesd_service = {
    @{The directory containing the root of the cache.}
    'dir' : string

    @{security context as which the kernel will perform operations to access the cache}
    'secctx' ? string

    @{culling limits, in percent}
    'bcull' ? long(0..100)
    'brun' ? long(0..100)
    'bstop' ? long(0..100)
    'fcull' ? long(0..100)
    'frun' ? long(0..100)
    'fstop' ? long(0..100)

    @{a tag to distinguish multiple caches}
    'tag' ? string


    @{The size of the tables holding the lists of cullable objects in the cache in log2}
    'culltable' ? long(12..20)

    @{Disable culling}
    'nocull' ? boolean

    @{a numeric bitmask to control debugging in the kernel module}
    'debug' ? long(0..7)
};
