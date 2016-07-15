object template automatic;

# mock pkg_repl
function pkg_repl = { null; };

include 'components/afsclt/config';

prefix '/software/components/afsclt';

# remove the dependencies that cannot be validated successfully
'dependencies' = null;

'cachemount' = '/afscache';
'cachesize' = 'AUTOMATIC';
'cellservdb' = 'http://grand.central.org/dl/cellservdb/CellServDB';
'dispatch' = true;
'enabled' = 'yes';
'thiscell' = 'in2p3.fr';

