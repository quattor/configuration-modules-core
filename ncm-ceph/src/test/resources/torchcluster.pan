template torchcluster;

include 'components/ceph/v2/schema';
bind '/software/components/ceph' = ceph_component;
prefix '/software/components/ceph';
'ceph_version' = '15.2.8';
'release' ='Octopus';

prefix 'orchestrator/cluster';

variable CEPH_MON_HOSTS = list('cephmon1.test.nw', 'cephmon2.test.nw', 'cephmon3.test.nw');
variable CEPH_OSD_HOSTS = list('cephosd1.test.nw', 'cephosd2.test.nw');

'hosts' = {
    hosts = dict();
    foreach(id; host; CEPH_MON_HOSTS){
        hosts[host] =  dict(
            'hostname', host,
            'addr', host,
            'labels', list('mon', 'mds', 'mgr')
           );
    };
    foreach(id; host; CEPH_OSD_HOSTS){
        hosts[host] = dict('hostname', host);
    };
    hosts;
};

'mon/placement/hosts' = CEPH_MON_HOSTS;
'mgr/placement/label' = 'mgr';
'mgr/placement/count' = 3;
'mds/r0/service_id' = 'cephfs';
'mds/r0/placement/label' = 'mds';
'osd/r1/encrypted' = true;
'osd/r1/placement/host_pattern' = '*';
'osd/r1/data_devices/all' = true;
'osd/r0/service_id' = 'nvme_drives';
'osd/r0/encrypted' = true;
'osd/r0/placement/host_pattern' = 'fastnode*';
'osd/r0/data_devices/rotational' = 0;

prefix 'orchestrator/initcfg/global';
'mon_host' = list('host1.aaa.be', 'host2.aaa.be', 'host3.aaa.be');
'fsid' = '8c09a56c-5859-4bc0-8584-d2c2232d62f6';

prefix 'orchestrator/configdb';
'global/op_queue' = 'wpq';
'global/mon_osd_down_out_subtree_limit' = 'rack';
'mds/mds_max_purge_ops_per_pg' = 10.0;
'mgr/modules/dashboard/server_addr' = 'localhost';
'mgr/modules/dashboard/server_port' = '7000';
'mgr/modules/telemetry/contact' = 'me';

