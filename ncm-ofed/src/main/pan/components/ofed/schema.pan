# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/ofed/schema;

include 'quattor/types/component';

## openib options (OPENIBOPTS)
type component_ofed_openib_options = {
    "onboot" : boolean = true

    ## MAD datagrams priority
    "renice_ib_mad" : boolean = false

    ## disable for large clusters
    "set_ipoib_cm" : boolean = true
    "set_ipoib_channels" : boolean = false

    ## SRP High Availability
    "srpha_enable" : boolean = false
    "srp_daemon_enable" : boolean = false

    ## IPoIB MTU setting
    "ipoib_mtu" : long = 32*1024

    # autotuning
    "run_sysctl" : boolean = true
    "run_affinity_tuner" : boolean = true
    "run_mlnx_tune" : boolean = false

    # description
    "node_desc" ? string # eg will default to hostname -s
    "node_desc_update_timeout" : long(0..) = 120
    "node_desc_time_before_update" : long(0..) = 10
    "post_start_delay" : long(0..) = 0

} = nlist();

## openib modules (OPENIBMODULES)
type component_ofed_openib_modules = {
    "ucm" : boolean = false
    "umad" : boolean = true
    "uverbs" : boolean = true

    ## RDAM CM (connected mode and unreliable datagram)
    "rdma_cm" : boolean = true
    "rdma_ucm" : boolean = true

    ## IPoIB
    "ipoib" : boolean = true
    "e_ipoib" : boolean = false

    ## SDP (Socket Direct Protocol)
    "sdp" : boolean = false

    ## SRP SCSI RDMA Protocol
    "srp" : boolean = false
    ## SRP Target
    "srpt" : boolean = false

    ## Reliable datagram socket
    "rds" : boolean = false

    ## ISCSI RDMA
    "iser" : boolean = false

    "mlx4_vnic" : boolean = false
    "mlx4_fc" : boolean = false
} = nlist();

## openib modules (OPENIBHARDWARE)
type component_ofed_openib_hardware = {
    ## Mellanox
    ## Inifinihost III
    "mthca" : boolean = false
    ## Connectx et al
    "mlx4" : boolean = false
    "mlx5" : boolean = false

    ## Mellanox ethernet
    "mlx_en" : boolean = false

    ## Qlogic
    "ipath" : boolean = false
    "qib" : boolean = false

    ## Qlogic ethernet
    "qlgc_vnic" : boolean = false

    ## Chelsio T3
    "cxgb3" : boolean = false
    ## NetEffect
    "nes" : boolean = false
} = nlist();


type component_ofed_openib = {
    ## OPENIBCFG
    "config" : string = "/etc/infiniband/openib.conf"

    "options" : component_ofed_openib_options
    "modules" : component_ofed_openib_modules

    ## at least one needs to be on
    "hardware" : component_ofed_openib_hardware
} = nlist();

type component_ofed_type = {
    include structure_component
    "openib" : component_ofed_openib
};

bind "/software/components/ofed" = component_ofed_type;
