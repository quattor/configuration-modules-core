object template config;

include 'metaconfig/chrony/config';

prefix '/software/components/metaconfig/services/{/etc/chrony.conf}/contents';
'server/0/hostname' = 'ntp.date.org';
'server/0/flags' = list('iburst', 'trust');
'server/1/hostname' = 'ntp2.date.org';
'pool/0/hostname' = 'pool.ntp.org';
'pool/0/flags' = list('iburst');
'pool/0/options/maxsources' = 6;
'flags' = list('rtcsync');
'makestep/threshold' = 0.1;
'makestep/limit' = 3;
'network/0/action' = 'allow';
'network/0/host' = '127.0.0.1';
'network/1/action' = 'deny';
'network/1/host' = '192.168.1.0/24';
'driftfile' = '/var/lib/chrony/drift';
'keyfile' = '/etc/chrony.keys';

