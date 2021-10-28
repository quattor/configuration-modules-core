object template fstab;

include 'fstab_simple';

prefix '/software/components/nfs/mounts/4';
'device' = '1.2.3.4@o2ib:5.6.7.8@o2ib:/thename';
'mountpoint' = '/mymount';
'fstype' = 'lustre';
'options' = 'defaults,user_xattr,_netdev,retry=10';
