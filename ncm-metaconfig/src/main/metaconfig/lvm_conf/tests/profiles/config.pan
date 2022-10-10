object template config;

include 'metaconfig/lvm_conf/config';

prefix "/software/components/metaconfig/services/{/etc/lvm/lvmlocal.conf}/contents";

"global" = dict('event_activation', 0);
"activation" = dict('activation_mode', 'degraded');
