object template config;

include 'metaconfig/opennebula/config';

prefix "/software/components/metaconfig/services/{/etc/aii/opennebula.conf}/contents";
"sections/0/name" = 'rpc';
"sections/0/password" = 'a_good_pass_here';
"sections/0/host" = 'localhost';
"sections/1/name" = 'node\d+.example.com';
"sections/1/password" = 'second_pass_here';
"sections/1/host" = 'my.hostname.com';
"sections/1/port" = 6666;
"sections/1/user" = "serveradmin";

