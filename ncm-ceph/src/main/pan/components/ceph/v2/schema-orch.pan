declaration template components/${project.artifactId}/v2/schema-orch;

@documentation{ hosts to add to orchestrator
hostname should be hostname as displayed with 'hostname' command
 }
type ceph_orch_host_spec = {
    'service_type' : choice('host') = 'host'
    'addr' ? type_hostname
    'hostname' : type_hostname
    'labels' ? string[]
};

@documentation{ where to deploy service, by label, hostname, host_pattern.
    It is also possible to specify the number of daemons for this service }
type ceph_orch_service_placement = {
    'hosts' ? type_hostname[]
    'label' ? string
    'host_pattern' ? string
    'count' ? long(1..)
};
@documentation{ declare placement of mon, mds and mgr daemons }
type ceph_orch_service_spec = {
    'placement' : ceph_orch_service_placement
    'unmanaged' ? boolean
};
@documentation{ ceph orchestrator spec for monitors }
type ceph_orch_mon_spec = {
    include ceph_orch_service_spec
    'service_type' : choice('mon') = 'mon'
};

@documentation{ ceph orchestrator spec for ceph-mgr }
type ceph_orch_mgr_spec = {
    include ceph_orch_service_spec
    'service_type' : choice('mgr') = 'mgr'
};

@documentation { mds service spec. service_id is file system name }
type ceph_orch_mds_spec = {
    include ceph_orch_service_spec
    'service_type' : choice('mds') = 'mds'
    'service_id' : string
};

@documentation{ ceph orchestrator osd placement }
type ceph_orch_osd_placement = {
    'host_pattern' ? string
};

@documentation{ ceph orchestrator spec for osd device filtering }
type ceph_orch_osd_devices = {
    'model' ? string
    'rotational' ? long(0..1)
    'vendor' ? string
    'size' ? string
    'all' ? boolean
    'limit' ? long # Not recommended
};

@documentation{ ceph orchestrator spec for osds.
See https://docs.ceph.com/en/latest/cephadm/drivegroups/#osd-service-specification }
type ceph_orch_osd_spec = {
    'service_type' : choice('osd') = 'osd'
    'service_id' : string = 'default_drive_group'
    'placement' : ceph_orch_osd_placement
    'data_devices' ? ceph_orch_osd_devices
    'db_devices' ? ceph_orch_osd_devices
    'wal_devices' ? ceph_orch_osd_devices
    'encrypted' ? boolean
    'db_slots' ? long
    'wal_slots' ? long
    'filter_logic' ? choice('AND', 'OR')
    'osds_per_device' ? long
};

@documentation { all specifications deployable with ceph orch apply -i }
type ceph_orch_cluster = {
    'hosts' ? ceph_orch_host_spec{}
    'mon' ? ceph_orch_mon_spec
    'mgr' ? ceph_orch_mgr_spec
    'mds' ? ceph_orch_mds_spec{}
    'osd' ? ceph_orch_osd_spec{}
};

@documentation{ ceph orchestrator type }
type ceph_orch = {
    'backend' : choice('cephadm') = 'cephadm'
    'cluster' : ceph_orch_cluster
    'configdb' ? ceph_configdb
    'initcfg' ? ceph_configfile
};

