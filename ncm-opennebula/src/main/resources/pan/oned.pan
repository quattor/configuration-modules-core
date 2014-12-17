unique template metaconfig/opennebula/oned;

include 'metaconfig/opennebula/schema';

bind "/software/components/metaconfig/services/{/etc/one/oned.conf}/contents/oned" = opennebula_oned;

prefix "/software/components/metaconfig/services/{/etc/one/oned.conf}";
"daemon/0" = "opennebula";
"module" = "opennebula/oned";
"mode" = 0640;
"owner" = "oneadmin";
"group" = "oneadmin";
