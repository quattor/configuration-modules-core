object template dual_stack_localhost;

include 'components/hostsfile/config-common';

prefix '/software/components/hostsfile';

'active' = true;
'file' = '/tmp/hosts.local';
'takeover' = true;
'entries' ?= dict();

# IPv4
'entries' = merge(SELF, HOSTSFILE_LOCALHOST4);

# IPv6
'entries' = merge(SELF, HOSTSFILE_LOCALHOST6);
