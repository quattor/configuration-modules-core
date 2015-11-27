object template cgconfig;

include 'metaconfig/cgroups/cgconfig';

prefix "/software/components/metaconfig/services/{/etc/cgconfig.conf}/contents";
"mount" = append(dict('controller', 'name=abc', 'path', 'a/b/c'));
"mount" = append(dict('controller', 'ns', 'path', 'ns/abc'));
