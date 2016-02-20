object template config;

include 'metaconfig/nrpe/config';

prefix "/software/components/metaconfig/services/{/etc/nagios/nrpe.cfg}/contents";
"allowed_hosts/0" = "a";
"allowed_hosts/1" = "b";

"command/cmd" = "foobar";
"command/mycmd" = "morefoobar";
"include/0" = "/foo/0";
"include/1" = "/foo/1";
"include_dir/0" = "/bar-0";
"include_dir/1" = "/bar-1";
