object template config;

include 'metaconfig/mlocate/config';

prefix "/software/components/metaconfig/services/{/etc/updatedb.conf}/contents";
"prunefs" = list("xfs", "afs");
"prunenames" = list("tmpfs");
"prunepaths" = list("/gpfs", "/tmp");
"prune_bind_mounts" = true;

