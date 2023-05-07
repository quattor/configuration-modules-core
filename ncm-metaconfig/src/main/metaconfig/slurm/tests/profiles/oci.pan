object template oci;

function pkg_repl = { null; };
include 'metaconfig/slurm/oci';
'/software/components/metaconfig/dependencies' = null;

prefix "/software/components/metaconfig/services/{/etc/slurm/oci.conf}/contents";
'DisableCleanup' = true;
'SrunArgs' = list('foo', '--bar');
