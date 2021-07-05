# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/yumdnf/schema;

include 'components/spma/yum/schema';

type component_spma_yumdnf = {
    include component_spma_yum
    @{configure modules (or not). modules configuration is under /software/modules}
    'modules' : boolean = false
};
