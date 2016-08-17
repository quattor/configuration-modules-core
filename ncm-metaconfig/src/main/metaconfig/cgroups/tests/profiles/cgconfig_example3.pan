object template cgconfig_example3;

prefix '/software/components/accounts';
'users/root' = dict();
'groups/root' = dict();
'groups/webmaster' = dict();
'groups/ftpmaster' = dict();

include 'metaconfig/cgroups/cgconfig';

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents";
"mount/cpuacct" = '/mnt/cgroups/cpu';
"mount/cpu" = '/mnt/cgroups/cpu';

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/group/{daemons/www}";
"controllers/cpu/cpu.shares" = '1000';
"perm/task" = dict(
    'uid', 'root',
    'gid', 'webmaster',
    'fperm', '770',
);
"perm/admin" = dict(
    "uid", "root",
    "gid", "root",
    "dperm", "775",
    "fperm", "744",
);

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/group/{daemons/ftp}";
"controllers/cpu/cpu.shares" = '500';
"perm/task" = dict(
    'uid', 'root',
    'gid', 'ftpmaster',
    'fperm', '774',
);
"perm/admin" = dict(
    "uid", "root",
    "gid", "root",
    "dperm", "755",
    "fperm", "700",
);
