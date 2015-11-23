object template cgrules;

include 'metaconfig/cgroups/cgrules';

prefix "/software/components/metaconfig/services/{/etc/cgrules.conf}/contents/rules/0";
"user" = dict('name', 'woohoo');
"controllers" = list('cpu', 'cpuacct');
"destination" = "a/b/c";


prefix "/software/components/metaconfig/services/{/etc/cgrules.conf}/contents/rules/1";
"user" = dict('group', 'woohoogroup');
"process" = "sshd";
"controllers" = list('memory', 'devices');
"destination" = "a/b/d";

prefix "/software/components/metaconfig/services/{/etc/cgrules.conf}/contents/rules/2";
"user" = dict('ditto', true);
"controllers" = list('*');
"destination" = "a/b/e";

prefix "/software/components/metaconfig/services/{/etc/cgrules.conf}/contents/rules/3";
"user" = dict('any', true);
"controllers" = list('cpuset', 'name=xyz');
"destination" = "a/b/f";
