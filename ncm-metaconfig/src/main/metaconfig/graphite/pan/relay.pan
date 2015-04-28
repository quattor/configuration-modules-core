unique template metaconfig/graphite/relay;

include 'metaconfig/graphite/schema';

bind "/software/components/metaconfig/services/{/etc/carbon/relay-rules.conf}/contents" = carbon_relay_relay_rules;

prefix "/software/components/metaconfig/services/{/etc/carbon/relay-rules.conf}";
"daemons/carbon-relay" = "restart";
"module" = "graphite/relay-rules";
"mode" = 0644;

prefix "/software/components/metaconfig/services/{/etc/carbon/relay-rules.conf}/contents";

# needs at least one default entry
"main/0" = nlist(
    "name","default",
    "default", true, # only for default rule!
    "pattern", ".*", # not used when default is true!
    "destinations", list("127.0.0.1:2004:a", "127.0.0.1:2104:b"),
);
