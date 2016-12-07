object template shorewall;

@{shorewall.conf}

include 'components/shorewall/schema';
bind '/config' = component_shorewall_shorewall;

prefix '/config';

'ip_forwarding' = 'On';
'tc_enabled' = 'Simple';
'blacklist' = list('RELATED', 'UNTRACKED');
'maclist_ttl' = 7;
# true is tested via startup_enabled and default true value
'basic_filters' = false;
