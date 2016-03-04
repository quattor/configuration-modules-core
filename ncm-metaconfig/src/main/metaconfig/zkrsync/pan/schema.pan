declaration template metaconfig/zkrsync/schema;

include 'pan/types';

function zkrsync_has_one_role = {
    if (is_defined(SELF['destination'])  && is_defined(SELF['source'])) {
        error("Zkrsync client can't be source AND destination");
    } else if( !is_defined(SELF['destination'])  && !is_defined(SELF['source'])) {
        error("Zkrsync client must be source OR destination");
    } else {
        true;
    };
};

@{ type for configuring the zkrsync config file @}
type zkrsync_config = {
    # zk opts
    'servers' : string[]
    'user' ? string 
    'passwd' ? string
    # Role opts, exactly one of both
    'destination' ? boolean
    'source' ? boolean
    # session opts
    'session' ? string
    'dryrun' ? boolean = false
    'rsyncpath' : string
    'rsubpaths' ? string[]
    'excludere' : string = '$^'
    'excl_usr' ? string = 'root'
    'depth' ? long(1..) = 3
    # source opts
    'delete' ? boolean = false
    'checksum' ? boolean = false
    'hardlinks' ? boolean = false
    # client opts
    'verifypath' ? boolean = true
    'domain' ? string
    'verbose' ? boolean = false
    'info' ? boolean = false
    # destination opts
    'startport' ? long = 4444
} with zkrsync_has_one_role(SELF);


