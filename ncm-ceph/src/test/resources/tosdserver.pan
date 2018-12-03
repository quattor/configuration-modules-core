template tosdserver;

include 'components/ceph/v2/schema';
bind '/software/components/ceph' = ceph_component;

prefix '/software/components/ceph';
'ceph_version' = '12.2.*';
'daemons/max_add_osd_failures' = 3;
prefix '/software/components/ceph/daemons/osds';

"sdb" = dict('class', 'hdd');
"sdc" = dict();
"sdd" = dict('class', 'special');
"sde" = dict('dmcrypt', true);
"sdf" = dict();
"{mapper/osd01}" = dict();
"{mapper/osd02}" = dict();
