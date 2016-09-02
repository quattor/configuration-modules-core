object template config;

include 'metaconfig/opennebula/config';

prefix "/software/components/metaconfig/services/{/etc/aii/opennebula.conf}/contents";
"rpc/url" = "http://myhost:2366";
"rpc/password" = "mypassword";
"cluster.com/url" = "https://my.example.com";
"cluster.com/password" = "a_good_pass_here";
"cluster.com/user" = "serveradmin2";
"cluster.com/pattern" = 'node0\d+.cluster.com';
