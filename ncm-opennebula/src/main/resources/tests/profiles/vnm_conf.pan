object template vnm_conf;

include 'components/opennebula/schema';

bind "/metaconfig/contents/vnm_conf" = opennebula_vnm_conf;

"/metaconfig/module" = "vnm_conf";

prefix "/metaconfig/contents/vnm_conf";
"arp_cache_poisoning" = false;
