object template fireedge;


include 'components/opennebula/schema';

bind "/metaconfig/contents" = opennebula_fireedge;

"/metaconfig/module" = "yaml";

prefix "/metaconfig/contents";
"host" = "0.0.0.0";
"port" = 2929;
