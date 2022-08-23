# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/opennebula/sched;

type opennebula_sched_policy_conf = {
    "policy" : long(0..4) = 1
} = dict();

@documentation{
Type that sets OpenNebula scheduler
sched.conf
}
type opennebula_sched = {
    include opennebula_rpc_service
    @{buffer size in bytes for XML-RPC responses}
    "message_size" : long = 1073741824
    @{seconds to timeout XML-RPC calls to oned}
    "timeout" : long = 60
    @{seconds between two scheduling actions}
    "sched_interval" : long = 15
    @{maximum number of Virtual Machines scheduled in each scheduling
    action. Use 0 to schedule all pending VMs each time}
    "max_vm" : long = 5000
    @{maximum number of Virtual Machines dispatched in each
    scheduling action}
    "max_dispatch" : long = 30
    @{maximum number of Virtual Machines dispatched to each host in
    each scheduling action}
    "max_host" : long = 1
    @{perform live (1) or cold migrations (0) when rescheduling a VM}
    "live_rescheds" : long(0..1) = 0
    @{type of cold migration, see documentation for one.vm.migrate
      0 = save - default
      1 = poweroff
      2 = poweroff-hard}
    "cold_migrate_mode" : long(0..2) = 0
    @{this factor scales the VM usage of the system DS with
    the memory size. This factor can be use to make the scheduler consider the
    overhead of checkpoint files:
    system_ds_usage = system_ds_usage + memory_system_ds_scale * memory}
    "memory_system_ds_scale" : long = 0
    @{when set (true) the NICs of a VM will be forced to be in
    different Virtual Networks}
    "different_vnets" : boolean = true
    @{definition of the default scheduling algorithm
    - policy:
      0 = Packing. Heuristic that minimizes the number of hosts in use by
          packing the VMs in the hosts to reduce VM fragmentation
      1 = Striping. Heuristic that tries to maximize resources available for
          the VMs by spreading the VMs in the hosts
      2 = Load-aware. Heuristic that tries to maximize resources available for
          the VMs by using those nodes with less load
      3 = Custom.
          - rank: Custom arithmetic expression to rank suitable hosts based in
            their attributes
      4 = Fixed. Hosts will be ranked according to the PRIORITY attribute found
          in the Host or Cluster template}
    "default_sched" : opennebula_sched_policy_conf
    @{definition of the default storage scheduling algorithm
    - policy:
      0 = Packing. Tries to optimize storage usage by selecting the DS with
          less free space
      1 = Striping. Tries to optimize I/O by distributing the VMs across
          datastores.
      2 = Custom.
          - rank: Custom arithmetic expression to rank suitable datastores based
          on their attributes
      3 = Fixed. Datastores will be ranked according to the PRIORITY attribute
          found in the Datastore template}
    "default_ds_sched" : opennebula_sched_policy_conf
    @{definition of the default virtual network scheduler
    - policy:
      0 = Packing. Tries to pack address usage by selecting the VNET with
          less free leases
      1 = Striping. Tries to distribute address usage across VNETs.
      2 = Custom.
          - rank: Custom arithmetic expression to rank suitable datastores based
          on their attributes
      3 = Fixed. Virtual Networks will be ranked according to the PRIORITY
          attribute found in the Virtual Network template}
    "default_nic_sched" : opennebula_sched_policy_conf
    "log" : opennebula_log
};
