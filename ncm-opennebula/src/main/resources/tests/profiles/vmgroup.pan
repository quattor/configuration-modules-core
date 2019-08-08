object template vmgroup;

include 'components/opennebula/schema';

bind "/metaconfig/contents/vmgroup/ha_group" = opennebula_vmgroup;

"/metaconfig/module" = "vmgroup";

prefix "/metaconfig/contents/vmgroup/ha_group";
"anti_affined" = list('workers', 'backups');
"affined" = list('db', 'apps');
"role" = list(
    dict(
        "name", "backup",
        "host_anti_affined", list('1', '2', '3'),
        "policy", "ANTI_AFFINED",
    ),
    dict(
        "name", "apps",
        "host_affined", list('4', '5', '6'),
        "policy", "AFFINED",
    ),
);
"labels" = list("quattor", "quattor/ha_group");
"description" = "New HA VM group managed by quattor";
