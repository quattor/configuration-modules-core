object template action_attr;

include 'metaconfig/udev/action_attr';

prefix "/software/components/metaconfig/services/{/etc/udev/rules.d/50-attrs.rules}/contents";
prefix "action_attrs/0";

'action' = 'add|change';
'subsystem' = 'block';
'attributes/{queue/rotational}' = '0';
'attributes/justsomekey' = 'ok';

