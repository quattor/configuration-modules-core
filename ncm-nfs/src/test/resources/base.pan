unique template base;

# mock pkg_repl
function pkg_repl = { null; };
include 'components/nfs/config';
# delete spma dependency (requires configured spma component otherwise)
"/software/components/nfs/dependencies" = null;
