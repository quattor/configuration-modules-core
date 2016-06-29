object template testsession;

include 'metaconfig/zkrsync/config';

prefix "/software/components/metaconfig/services/{/etc/zkrs/default.conf}/contents";

"servers" = list('mds01.gent:2181', 'mds02.gent:2181', 'mds03.gent:2181');

'source' = true;
"domain" = 'ugent.be';
'excludere' = '$^';
'excl_usr' = '';
'info' = true;
'delete'= false;
'timeout' = 600;
'rsyncpath' = '/user/gent';
'rsubpaths' = list('2_gent/test/1', '3_gent/test/2');
'dropcache' = true;

