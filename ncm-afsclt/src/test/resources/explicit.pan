object template explicit;

# mock pkg_repl
function pkg_repl = { null; };

include 'components/afsclt/config';

prefix '/software/components/afsclt';

# remove the dependencies that cannot be validated successfully
'dependencies' = null;

'afs_mount' = '/afsmnt';
'cachemount' = '/var/afs/cache';
'cachesize' = '1422000';
'cellservdb' = 'http://grand.central.org/dl/cellservdb/CellServDB';
'dispatch' = true;
'enabled' = 'yes';
'thiscell' = 'in2p3.fr';
'thesecells' = list('cern.ch', 'morganstanley.com');
