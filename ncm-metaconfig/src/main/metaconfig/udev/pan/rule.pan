unique template metaconfig/udev/rule;
@documentation{
This example shows how to create a multiple rules. Please refer to rule schema for data structure.

SELF[digit] : represents each rule in the file
each rule consists of match_rule and assign_rule attributes:
each attribute can be dict of dict or dict of list of dict
dict of list of dict allows mulitple matching or multiple assign with different keys \
(example of this below, 'attrs[0]' attribute or 'run[0]' assign attribute)
match_rule attributes could have operator of 2 types, ==, and !=
assign_rule attributes could have operator of 3 types, =, := and +=

Refer to manpage udev(7) for keys.
As left|right brace key char in, they are represented as &lbrace; and &rbrace;

Rules to generate:
rule:
# ACTION=="add|change", ATTRS&lbrace;device&rbrace;=="0x1572", ATTRS&lbrace;vendor&rbrace;=="0x8086", DRIVERS=="i40e", \
#    SUBSYSTEM=="net", ATTR&lbrace;vendor&rbrace;="0x8086", RUN+="/sbin/ethtool --set-priv-flags '%k' \
#    disable-source-pruning on", RUN+="/sbin/ethtool --set-priv-flags '%k' disable-lldp off"
#2 rule: ENV&lbrace;DM_COOKIE&rbrace;=="?*", RUN+="/usr/sbin/dmsetup udevcomplete $env&lbrace;DM_COOKIE&rbrace;"
bind "/software/components/metaconfig/services/&lbrace;/etc/udev/rules.d/51-quattor.rules&rbrace;/contents" = udev_rules;
prefix "/software/components/metaconfig/services/&lbrace;/etc/udev/rules.d/51-quattor.rules&rbrace;";

First rule:
prefix "/software/components/metaconfig/services/&lbrace;/etc/udev/rules.d/51-quattor.rules&rbrace;/contents/rule/0";
'match_rule/action/value' = 'add|change';
'match_rule/action/operator' = '==';
'match_rule/subsystem/value'  = 'net';
'match_rule/subsystem/operator'  = '==';
'match_rule/drivers/value' = 'i40e';
'match_rule/drivers/operator' = '==';
'match_rule/attrs/0/key' = 'device';
'match_rule/attrs/0/value' = '0x1572';
'match_rule/attrs/0/operator' = '==';
'match_rule/attrs/1/key' = 'vendor';
'match_rule/attrs/1/value' = '0x8086';
'match_rule/attrs/1/operator' = '==';
'udev_assign_rule/run/0/value' = "/sbin/ethtool --set-priv-flags '%k' disable-source-pruning on";
'udev_assign_rule/run/0/operator' = "+=";
'udev_assign_rule/run/1/value' = "/sbin/ethtool --set-priv-flags '%k' disable-lldp off";
'udev_assign_rule/run/1/operator' = "+=";
'udev_assign_rule/attr/key' = 'vendor';
'udev_assign_rule/attr/value' = '0x8086';
'udev_assign_rule/attr/operator' = '=';

Second rule:
prefix "/software/components/metaconfig/services/&lbrace;/etc/udev/rules.d/51-quattor.rules&rbrace;/contents/rule/1";
'match_rule/env/0/key' = 'DM_COOKIE';
'match_rule/env/0/operator' = '==';
'match_rule/env/0/value' = '?*';
'udev_assign_rule/run/0/value' = "/usr/sbin/dmsetup udevcomplete $env&lbrace;DM_COOKIE&rbrace;";
'udev_assign_rule/run/0/operator' = "+=";
}
include 'metaconfig/udev/rule_schema/schema';
"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "udev/rule";
