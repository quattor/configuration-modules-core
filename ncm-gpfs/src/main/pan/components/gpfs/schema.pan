${componentschema}

include 'quattor/types/component';
include 'pan/types';

type gpfs_curl = {
    "usecurl" ? boolean = true
    "useccmcertwithcurl" ? boolean = false
    "usesindesgetcertcertwithcurl" ? boolean = false
};

type gpfs_cfg = {
    include gpfs_curl
    "url" : string
    "keyData" ? string
    "sdrrestore" : boolean = false
    "subnet" : string
};

type gpfs_base = {
    include gpfs_curl
    "rpms" : string[]
    "baseurl" : string
    "useproxy" ? boolean = false
    "useyum" : boolean = true
};

type gpfs_component = {
    include structure_component
    "base" : gpfs_base
    "cfg" : gpfs_cfg
};
