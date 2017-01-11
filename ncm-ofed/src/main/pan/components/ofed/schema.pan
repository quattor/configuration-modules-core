# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ofed/schema;

include 'quattor/types/component';

@documentation{openib options}
type component_ofed_openib_options = {
    "onboot" : boolean = true

    @{MAD datagrams priority}
    "renice_ib_mad" : boolean = false

    @{disable for large clusters}
    "set_ipoib_cm" : boolean = true
    "set_ipoib_channels" : boolean = false
    @{IPoIB MTU setting for CM}
    "ipoib_mtu" : long = 32 * 1024

    @{SRP High Availability}
    "srpha_enable" : boolean = false
    "srp_daemon_enable" : boolean = false

    @{autotuning}
    "run_sysctl" : boolean = true
    "run_affinity_tuner" : boolean = true
    "run_mlnx_tune" : boolean = false

    @{node description}
    "node_desc" ? string # eg will default to hostname -s
    "node_desc_update_timeout" : long(0..) = 120
    "node_desc_time_before_update" : long(0..) = 10
    "post_start_delay" : long(0..) = 0

    "cx3_eth_only" : boolean = false
} = dict();

@{openib modules to load}
type component_ofed_openib_modules = {
    "ucm" : boolean = false
    "umad" : boolean = true
    "uverbs" : boolean = true

    @{RDMA modes (connected mode and unreliable datagram)}
    "rdma_cm" : boolean = true
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

    "mlx4_vnic" : boolean = false
    "mlx4_fc" : boolean = false
    "mlx4_en" : boolean = false
} = dict();

@documentation{openib hardware modules to load}
type component_ofed_openib_hardware = {
    @{Mellanox Inifinihost III}
    "mthca" : boolean = false
    @{Mellanox ConnectX}
    "mlx4" : boolean = false
    "mlx5" : boolean = false

    @{Mellanox ethernet-only}
    "mlx_en" : boolean = false

    @{Qlogic}
    "ipath" : boolean = false
    "qib" : boolean = false

    @{Qlogic ethernet}
    "qlgc_vnic" : boolean = false

    @{Chelsio T3/T4}
    "cxgb3" : boolean = false
    "cxgb4" : boolean = false

    @{NetEffect}
    "nes" : boolean = false
} = dict();


type component_ofed_openib = {
    @{location of openibd config file}
    "config" : string = "/etc/infiniband/openib.conf"

    "options" : component_ofed_openib_options
    "modules" : component_ofed_openib_modules

    "hardware" : component_ofed_openib_hardware
} = dict() with {
    enabled = false;
    foreach(hw;en;SELF['hardware']) {
        if (en) {
            enabled = true;
        };
    };
    if (! enabled) {
        error('At least one openib hardware module must be enabled');
    };
    true;
};

type component_ofed_type = {
    include structure_component
    "openib" : component_ofed_openib
};
