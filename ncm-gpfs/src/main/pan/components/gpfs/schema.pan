# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/gpfs/schema;

include { 'quattor/schema' };

type component_gpfs_cfg = {
    "url"  : string
    "subnet" : string
    ## "useproxy" ? boolean = false
    "usecurl" ? boolean = true
    "useccmcertwithcurl" ? boolean = false
    "usesindesgetcertcertwithcurl" ? boolean = false
};

type component_gpfs_base = {
    "rpms" : string[]
    "baseurl"  : string
    "useproxy" ? boolean = false
    "usecurl" ? boolean = false
    "useccmcertwithcurl" ? boolean = false
    "usesindesgetcertcertwithcurl" ? boolean = false
};

type component_gpfs_type = {
    include structure_component
    "base" :  component_gpfs_base
    "cfg" :  component_gpfs_cfg
};

bind "/software/components/gpfs" = component_gpfs_type;
