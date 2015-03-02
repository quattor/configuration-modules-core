object template config;

include 'metaconfig/example/config';

prefix "/software/components/metaconfig/services/{/etc/example/exampled.conf}/contents";
"hosts" = list("server1", "server2");
"port" = 800;
"master" = false;
"description" = "My example";
