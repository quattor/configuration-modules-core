object template cgconfig;

prefix '/software/components/accounts';
'users/user1' = dict();
'users/user2' = dict();
'users/user3' = dict();
'users/user4' = dict();
'groups/group1' = dict();
'groups/group2' = dict();
'groups/group3' = dict();
'groups/group4' = dict();

include 'metaconfig/cgroups/cgconfig';

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents";
"mount/{name=abc}" = 'a/b/c';
"mount/ns" = 'ns/abc';

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/default/perm";
"task/uid" = "user1";
"task/gid" = "group1";
"task/fperm" = "022";
"admin/uid" = "user2";
"admin/gid" = "group2";
"admin/fperm" = "077";
"admin/dperm" = "077";

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/group/{my/special}/controllers";
"cpu" = dict(); # empty
"cpuacct" = dict(
    'cpu.shares', '100',
);

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/group/{my/special}/perm";
"task/uid" = "user3";
"task/gid" = "group3";
"task/fperm" = "022";
"admin/uid" = "user4";
"admin/gid" = "group4";
"admin/fperm" = "077";
"admin/dperm" = "077";

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/template/{my/users/%u}/controllers";
"memory" = dict();
"cpu" = dict(
    "cpu.shares", "250",
);
