object template ipv6;

include 'components/hostsfile/config-common';

prefix '/software/components/hostsfile';

'active' = true;
'file' = '/tmp/hosts.local';
'entries' ?= dict();

'entries' = merge(SELF, HOSTSFILE_LOCALHOST6);
