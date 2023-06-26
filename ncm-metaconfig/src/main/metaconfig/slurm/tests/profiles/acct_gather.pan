object template acct_gather;

function pkg_repl = { null; };
include 'metaconfig/slurm/acct_gather';
'/software/components/metaconfig/dependencies' = null;



prefix "/software/components/metaconfig/services/{/etc/slurm/acct_gather.conf}/contents";

"ProfileHDF5Dir" = "/some/shared/storage/path/mycluster";
"ProfileHDF5Default" = list("All");

