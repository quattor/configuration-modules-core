# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/sysconfig/schema;

include quattor/schema;

type component_sysconfig = {
    include structure_component
    'files' ? string{}{}
};

type '/software/components/sysconfig' = component_sysconfig;


