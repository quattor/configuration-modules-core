object template oneflow;

include 'components/opennebula/schema';

bind "/metaconfig/contents/oneflow" = opennebula_oneflow;

"/metaconfig/module" = "oneflow";

prefix "/metaconfig/contents/oneflow";
"host" = "0.0.0.0";
"lcm_interval" = 60;
"shutdown_action" = "terminate-hard";

