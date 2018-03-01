object template cgroups;

function pkg_repl = { null; };
include 'metaconfig/slurm/cgroups';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/cgroup.conf}/contents";
'CgroupAutomount' = true;

'ConstrainCores' = true;
'ConstrainRAMSpace' = true;
'ConstrainSwapSpace' = true;

'AllowedSwapSpace' = 10;

'TaskAffinity' = true;
