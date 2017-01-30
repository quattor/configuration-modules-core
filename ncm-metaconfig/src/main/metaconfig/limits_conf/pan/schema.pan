declaration template metaconfig/limits_conf/schema;

include 'pan/types';

type limits_conf_item = string with match(SELF,
    '^(core|data|fsize|memlock|nofile|rss|stack|cpu|nproc|as|max(sys)?logins|priority|locks|sigpending|msgqueue|nice|rtprio)$');

type limits_conf_entry = {
    'domain' : string
    'type' : string with match(SELF, '^(soft|hard|-)$')
    'item' : limits_conf_item
    'value' : long(-1..)
};

@{ type for configuring the limits.conf file @}
type limits_conf_file = {
    'entries' : limits_conf_entry[]
};

