${componentschema}

include 'quattor/types/component';

@documentation{openib options}
type component_ofed_openib_options = {
    @{Start HCA driver upon boot}
    "onboot" : boolean = true

    @{MAD datagrams thread priority}
    "renice_ib_mad" : boolean = false

    @{disable CM for IPoIB for large clusters}
    "set_ipoib_cm" : boolean = true
    "set_ipoib_channels" : boolean = false # deprecated in MLNX OFED 3.4
    @{IPoIB MTU setting for CM}
    "ipoib_mtu" : long(0..65536) = 32 * 1024 # deprecated in MLNX OFED 3.4

    @{SRP High Availability}
    "srpha_enable" : boolean = false
    "srp_daemon_enable" : boolean = false

    @{sysctl tuning}
    "run_sysctl" : boolean = true
    @{affinity tuning}
    "run_affinity_tuner" : boolean = true
    @{Enable MLNX autotuning}
    "run_mlnx_tune" : boolean = false

    @{node description}
    "node_desc" ? string # eg will default to hostname -s
    @{Max time in seconds to wait for node's hostname to be set}
    "node_desc_update_timeout" : long(0..) = 120
    @{Wait (in sec) before node description update}
    "node_desc_time_before_update" : long(0..) = 10
    @{Seconds to sleep after openibd start finished and before releasing the shell}
    "post_start_delay" : long(0..) = 0

    @{ConnectX-3 ethernet only}
    "cx3_eth_only" : boolean = false
} = dict();

@{openib modules to load}
type component_ofed_openib_modules = {
    "ucm" : boolean = false
    "umad" : boolean = true
    "uverbs" : boolean = true

    @{RDMA CM (connected mode) mode}
    "rdma_cm" : boolean = true
    @{RDMA UD (unreliable datagram) mode}
    "rdma_ucm" : boolean = true

    @{IPoIB}
    "ipoib" : boolean = true
    "e_ipoib" : boolean = false

    @{SDP (Socket Direct Protocol)}
    "sdp" : boolean = false

    @{SRP SCSI RDMA Protocol}
    "srp" : boolean = false
    @{SRP Target}
    "srpt" : boolean = false

    @{Reliable datagram socket}
    "rds" : boolean = false

    @{ISCSI RDMA}
    "iser" : boolean = false

    @{Mellanox ConnectX-3 Virtual NICs}
    "mlx4_vnic" : boolean = false # deprecated in MLNX OFED 3.4
    @{Mellanox ConnectX-3 FibreChannel over Ethernet}
    "mlx4_fc" : boolean = false # deprecated in MLNX OFED 3.4
    @{Mellanox ConnectX-3 Ethernet}
    "mlx4_en" : boolean = false # deprecated in MLNX OFED 3.4
} = dict();

@documentation{openib hardware modules to load}
type component_ofed_openib_hardware = {
    @{Mellanox Inifinihost III}
    "mthca" : boolean = false
    @{Mellanox ConnectX-2/3}
    "mlx4" : boolean = false
    @{Mellanox ConnectX-4/5 / ConnectIB}
    "mlx5" : boolean = false

    @{Mellanox ethernet-only}
    "mlx_en" : boolean = false

    @{Legacy Qlogic IB}
    "ipath" : boolean = false
    @{Qlogic/Intel TrueScale IB}
    "qib" : boolean = false

    @{Qlogic ethernet}
    "qlgc_vnic" : boolean = false

    @{Chelsio T3/T4}
    "cxgb3" : boolean = false
    "cxgb4" : boolean = false

    @{NetEffect}
    "nes" : boolean = false
} = dict();


@documentation{openib configuration}
type component_ofed_openib = {
    @{location of openibd config file}
    "config" : string = "/etc/infiniband/openib.conf"

    "options" : component_ofed_openib_options
    "modules" : component_ofed_openib_modules

    "hardware" : component_ofed_openib_hardware
} = dict() with {
    enabled = false;
    foreach(hw; en; SELF['hardware']) {
        if (en) {
            enabled = true;
        };
    };
    if (! enabled) {
        error('At least one openib hardware module must be enabled');
    };
    true;
};

type component_ofed_partition_property = {
    @{Port GUID}
    'guid' : string with match(SELF, '^(ALL(_(SWITCHES|V?CAS|ROUTERS))?|SELF|0x[0-9a-fA-F]{1,10})$')
    'membership' ? string with match(SELF, '^(limited|full|both)$')
};

@documentation{
    Partition entry
}
type component_ofed_partition = {
    @{partition key (aka PKey); default is 32767/0x7fff.
      (partition keys are unique; first name is used by OpenSM for same keys)}
    'key' : long(0..32767) = 32767
    @{support IPoiB in this partition}
    'ipoib' ? boolean
    @{Rate: e.g. 3 (10Gbps), 4 (20Gbps),...}
    'rate' ? long(0..8)
    @{MTU: e.g. 4 (2048 bytes), 5 (4096 bytes)}
    'mtu' ? long(0..5)
    @{Partition properties}
    'properties' : component_ofed_partition_property[]
};

@{Subnet manager configuration}
type component_ofed_opensm = {
    @{daemons to restart on configuration changes}
    "daemons" : string[] = list('opensmd')
    @{SM partitions configuration. Dict key is the partition name}
    "partitions" ? component_ofed_partition{}
    @{Node name map configuration. Dict key is the GUID starting with 'x' (the 0 is prefixed automatically)}
    "names" ? string{}
} with {
    if (exists(SELF['names'])) {
        foreach (guid; descr; SELF['names']) {
            if (!match(guid, '^x[0-9a-fA-F]{16}')) {
                error(format("opensm names key must be GUID, got %s", guid));
            };
        };
    };
    true;
};

type ${project.artifactId}_component = {
    include structure_component
    "openib" : component_ofed_openib
    "opensm" ? component_ofed_opensm
};
