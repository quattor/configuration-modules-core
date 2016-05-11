object template config;

include 'metaconfig/limits_conf/config';

prefix "/software/components/metaconfig/services/{/etc/security/limits.d/91-quattor.conf}/contents";

"entries/0" = dict('domain', 'ftp', 'type', 'hard', 'item', 'priority', 'value', 5);
"entries/1" = dict('domain', 'student', 'type', 'soft', 'item', 'maxlogins', 'value', 1);
"entries/2" = dict('domain', 'ceph', 'type', '-', 'item', 'nproc', 'value', 1048576);
"entries/3" = dict('domain', 'ceph', 'type', '-', 'item', 'nofile', 'value', 1048576);

