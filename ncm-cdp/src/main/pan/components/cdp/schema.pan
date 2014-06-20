# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/cdp/schema;

include { 'quattor/schema' };

type component_cdp = {
    include structure_component
    'configFile'   : string = '/etc/cdp-listend.conf'
    'port'         ? type_port
    'nch'          ? string
    'nch_smear'    ? long(0..)
    'fetch'        ? string
    'fetch_offset' ? long(0..)
    'fetch_smear'  ? long(0..)
};

bind '/software/components/cdp' = component_cdp;
