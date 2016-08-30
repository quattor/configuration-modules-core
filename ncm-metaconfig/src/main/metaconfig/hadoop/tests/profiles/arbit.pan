object template arbit;

include 'metaconfig/hadoop/config';


prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}";
"module" = "hadoop/main";

prefix "/software/components/metaconfig/services/{/etc/hadoop/conf.quattor/core-site.xml}/contents";
'a/b/c.d/e' = dict(
    'f', 'g',
    'h', 'i',
);

'a/z/y/x' = true;
'a/z/v/w' = false;
