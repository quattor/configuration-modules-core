# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/monitord;

@documentation{
OpenNebula monitoring network setup.
Reads messages from monitor agent.
}
type opennebula_monitord_network = {
    @{Network address to bind the UDP listener to}
    "address" : type_ipv4
    @{Agents will send updates to this monitor address
    if "auto" is used, agents will detect the address
    from the ssh connection frontend -> host ($SSH_CLIENT),
    "auto" is not usable for HA setup}
    "monitor_address" : string = "auto"
    @{Monitoring listening port}
    "port" : type_port = 4124
    @{Number of processing threads}
    "threads" : long(1..) = 8
    @{Absolute path to public key (agents). Empty for no encryption}
    "pubkey" : string = ""
    @{Absolute path to private key (monitord). Empty for no encryption}
    "privkey" : string = ""
};

@documentation{
OpenNebula probes Configuration.
Time in seconds to execute each probe category.
}
type opennebula_probes_period = {
    @{Heartbeat for the host}
    "beacon_host" : long(1..) = 30
    @{Host static/configuration information}
    "system_host" : long(1..) = 600
    @{Host variable information}
    "monitor_host" : long(1..) = 120
    @{VM status (ie. running, error, stopped...)}
    "state_vm" : long(1..) = 5
    @{VM resource usage metrics}
    "monitor_vm" : long(1..) = 30
    @{When monitor probes have been stopped more than sync_vm_state
    seconds, send a complete VM report}
    "sync_state_vm" : long(1..) = 180
} = dict();

@documentation{
Type that sets the monitord configuration file
}
type opennebula_monitord = {
    "log" : opennebula_log
    "db" : opennebula_mysql_db = dict('connections', 15)
    "network" : opennebula_monitord_network
    "probes_period" : opennebula_probes_period
    "im_mad" : opennebula_im[] = list(
        dict(
            "name", "kvm",
            "sunstone_name", "KVM",
            "arguments", "-r 3 -t 15 -w 90 kvm",
            "threads", 0,
        ),
        dict(
            "name", "lxd",
            "sunstone_name", "LXD",
            "arguments", "-r 3 -t 15 -w 90 lxd",
            "threads", 0,
        ),
        dict(
            "name", "firecracker",
            "sunstone_name", "Firecracker",
            "arguments", "-r 3 -t 15 -w 90 firecracker",
            "threads", 0,
        ),
        dict(
            "name", "vcenter",
            "sunstone_name", "VMWare vCenter",
            "arguments", "-c -t 15 -r 0 vcenter",
        ),
    )
};
