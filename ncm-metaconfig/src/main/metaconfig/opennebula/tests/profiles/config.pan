object template config;

include 'metaconfig/opennebula/config';

prefix "/software/components/metaconfig/services/{/etc/aii/opennebula.conf}/contents";
"rpc/host" = "myhost";
"rpc/password" = "mypassword";
"cluster.com/host" = "anotherhost";
"cluster.com/password" = "a_good_pass_here";
"cluster.com/port" = 6666;
"cluster.com/user" = "serveradmin2";
"cluster.com/pattern" = 'node0\d+.cluster.com';
