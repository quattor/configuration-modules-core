object template group_one;

include 'components/opennebula/schema';

bind "/metaconfig/contents/group/gvo01" = opennebula_group;

"/metaconfig/module" = "group";

prefix "/metaconfig/contents/group/gvo01";
"description" = "gvo01 group managed by quattor";
"labels" = list("quattor", "quattor/VO");
