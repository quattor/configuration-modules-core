object template group_one;

include 'components/opennebula/schema';

bind "/metaconfig/contents/group" = opennebula_group;

"/metaconfig/module" = "group";

prefix "/metaconfig/contents/group";
"group" = "gvo01";
"description" = "gvo01 group managed by quattor";
