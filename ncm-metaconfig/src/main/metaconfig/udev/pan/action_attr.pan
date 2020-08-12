unique template metaconfig/udev/action_attr;

include 'metaconfig/udev/schema';

prefix "/software/components/metaconfig/services/{/etc/udev/rules.d/50-attrs.rules}";

"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "udev/action_attr";

bind "/software/components/metaconfig/services/{/etc/udev/rules.d/50-attrs.rules}/contents/action_attrs" =
    udev_action_attrs;

