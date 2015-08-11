object template sunstone;

include 'components/opennebula/schema';

bind "/metaconfig/contents/sunstone" = opennebula_sunstone;

"/metaconfig/module" = "sunstone";

prefix "/metaconfig/contents/sunstone";
"host" = "0.0.0.0";
"tmpdir" = "/tmp";
