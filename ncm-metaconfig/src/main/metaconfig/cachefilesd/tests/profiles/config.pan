object template config;

include 'metaconfig/cachefilesd/config';

prefix "/software/components/metaconfig/services/{/etc/cachefilesd.conf}/contents";
'dir' = "/my/path";
'secctx' = "special:label";
'bcull' = 20;
'brun' = 10;
'bstop' = 30;
'fcull' = 21;
'frun' = 11;
'fstop' = 31;
'tag' = 'tag';
'culltable' = 14;
'nocull' = true;
'debug' = 4;
