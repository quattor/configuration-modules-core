object template config;

include 'metaconfig/rpcidmapd/config';

prefix "/software/components/metaconfig/services/{/etc/idmapd.conf}/contents";

"General/Domain" = "MyDomain";

"Static/firstrealm/user" = "localuser";
"Static/otherrealm/otheruser" = "samelocaluser";
