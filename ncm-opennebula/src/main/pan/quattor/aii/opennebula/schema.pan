declaration template quattor/aii/opennebula/schema;

include 'pan/types';

final variable OPENNEBULA_AII_MODULE_NAME ?= 'NCM::Component::opennebula';

@documentation{
Function to validate all aii_opennebula hooks
}
function validate_aii_opennebula_hooks = {
    if (ARGC != 1) {
        error("%s: requires only one argument", FUNCTION);
    };

    if (! exists(SELF[ARGV[0]])) {
        error("%s: no %s hook found.", FUNCTION, ARGV[0]);
    };

    hk = SELF[ARGV[0]];
    found = false;
    ind = 0;
    foreach(i; v; hk) {
        if (exists(v['module']) && v['module'] == OPENNEBULA_AII_MODULE_NAME) {
            if (found) {
                error("%s: second aii_opennebula %s hook found", FUNCTION, ARGV[0]);
            } else {
                found = true;
                ind = i;
            };
        };
    };

    if (! found) {
        error("%s: no aii_opennebula %s hook found", FUNCTION, ARGV[0]);
    };

    if (ind != length(hk) - 1) {
        error("%s: aii_opennebula %s hook has to be last hook (idx %s of %s)",
        FUNCTION, ARGV[0], ind, length(hk));
    };

    # validate the hook
    true;
};

type structure_aii_opennebula = {
    "module" : string with SELF == OPENNEBULA_AII_MODULE_NAME
    @{force create image from scratch, also stop/delete vm.
    VM images are not updated, if you want to resize or modify an available
    image from scratch use remove hook first.}
    "image" : boolean = false
    @{force (re)create template, also stop/delete vm}
    "template" : boolean = false
    @{instantiate template (i.e. make vm)}
    "vm" : boolean = false
    @{vm is placed onhold, if false the VM execution is scheduled asap}
    "onhold" : boolean = true
};

type opennebula_vmtemplate_vnet = string{} with {
    # check if all entries in the map have a network interface
    foreach (k; v; SELF) {
        if (! exists("/system/network/interfaces/" + k)) {
            error("entry: %s in the vnet map is not available from /system/network/interfaces tree", k);
        };
    };
    # check if all interfaces have an entry in the map
    foreach (k; v; value("/system/network/interfaces")) {
        if (
            (! exists(SELF[k])) &&
            (! exists(v['plugin']['vxlan'])) && # VXLAN interfaces do not need vnet mapping
            (! (exists(v['type']) && match(v['type'], '^(Bridge|OVSBridge|IPIP)$'))) && # special types no real dev
            (! (exists(v['driver']) && (v['driver'] == 'bonding'))) && # bonding interface is no real device
            (! (match(k, '^ib\d+$') && exists("/hardware/cards/ib/" + k))) # It's ok if this is an IB device
        ) {
            error("/system/network/interfaces/%s has no entry in the vnet map", k);
        };
    };
    true;
};

type opennebula_rdm_disk = string{} with {
    foreach (k; v; SELF) {
        if (! is_absolute_file_path(v)) {
            error("entry: %s in the RDM disk map %s is not a valid file path", v, k);
        };
    };
    true;
};

type opennebula_vmtemplate_datastore = string{} with {
    # check is all entries in the map have a hardrive
    foreach (k; v; SELF) {
        if (! exists("/hardware/harddisks/" + k)) {
            error("/hardware/harddisks/%s has no entry in the datastores map", k);
        };
    };
    # check if all interfaces have an entry in the map
    foreach (k; v; value("/hardware/harddisks")) {
        if (! exists(SELF[k])) {
            error("entry: %s in the datastore map is not available from /hardware/harddisks tree", k);
        };
    };
    true;
};


function is_consistent_memorybacking = {
    # check memorybacking values
    foreach (memory; data; SELF) {
        foreach (memory2; data2; SELF) {
            if (SELF[memory] == SELF[memory2] && memory != memory2) {
                error("entry: %s appears several times within memorybacking list", data);
            };
        };
    };
    foreach (memory; data; SELF) {
        if (! match('^(hugepages|nosharepages|locked)$', SELF[memory])) {
            error("entry: %s is not a valid memorybacking value", data);
        };
    };
    true;
};

@documentation{
Type that checks if the network interface is available from the quattor tree
}
type valid_interface_ignoremac = string with {
    if (! exists("/system/network/interfaces/" + SELF)) {
        error("ignoremac.interface: '%s' is not available from /system/network/interfaces tree", SELF);
    };
    true;
};

@documentation{
Type that sets which net interfaces/MACs
will not include MAC values within ONE templates
}
type opennebula_ignoremac = {
    "macaddr" ? type_hwaddr[]
    "interface" ? valid_interface_ignoremac[]
};

@documentation{
Type that changes resources owner/group permissions.
By default opennebula-aii generates all the resources as oneadmin owner/group.
  owner: OpenNebula user id or user name
  group: OpenNebula group id or username
  mode:  Octal notation, e.g. 0600
}
type opennebula_permissions = {
    "owner"  ? string
    "group" ? string
    "mode" ? long
};

@documentation{
It is possible to discover PCI devices in the hosts
and assign them to Virtual Machines for the KVM host.
I/O MMU and SR-IOV must be supported and enabled by the host OS and BIOS.
More than one PCI option can be added to attach more than one PCI device to the VM.
The device can be also specified without all the type values.
PCI values must be hexadecimal (0xhex)
If the PCI values are not found in any host the VM is queued waiting for the
required resouces.

"onehost show <host>" command gives us the list
of PCI devices and "vendor", "device" and "class" values within PCI DEVICES section
as example:

VM ADDR    TYPE           NAME
   06:00.1 15b3:1002:0c06 MT25400 Family [ConnectX-2 Virtual Function]

  VM: The VM ID using that specific device. Empty if no VMs are using that device.
  ADDR: PCI Address.
  TYPE: Values describing the device. These are VENDOR:DEVICE:CLASS.
        These values are used when selecting a PCI device do to passthrough.
  NAME: Name of the PCI device.

In this case to request this IB device we should set:
  vendor: 0x15b3
  device: 0x1002
  class:  0x0c06

For more info:
https://docs.opennebula.io/6.10/open_cluster_deployment/kvm_node/pci_passthrough.html
}
type opennebula_vmtemplate_pci = {
    @{first value from onehost TYPE section}
    "vendor" ? long
    @{second value from onehost TYPE section}
    "device" ? long
    @{third value from onehost TYPE section}
    "class" ? long
};

@documentation{
Type that sets VM Groups and Roles for a specifc VM.
VMGroups are placed by dynamically generating the requirement (SCHED_REQUIREMENTS)
of each VM an re-evaluating these expressions.

Moreover, the following is also considered:

The scheduler will look for a host with enough capacity for an affined set of VMs.
If there is no such host all the affined VMs will remain pending.

If new VMs are added to an affined role, it will pick one of the hosts where the VMs
are running. By default, all should be running in the same host but if you manually
migrate a VM to another host it will be considered feasible for the role.

The scheduler does not have any synchronization point with the state of the VM group,
it will start scheduling pending VMs as soon as they show up.

Re-scheduling of VMs works as for any other VM, it will look for a different host
considering the placement constraints.

For more info:
https://docs.opennebula.io/6.10/management_and_operations/capacity_planning/affinity.html
}
type opennebula_vmtemplate_vmgroup = {
    "vmgroup_name" : string
    "role" : string
};

@documentation{
Type that sets placement constraints and preferences for the VM, valid for all hosts
More info: https://docs.opennebula.io/6.10/management_and_operations/capacity_planning/scheduling.html
}
type opennebula_placements = {
    @{Boolean expression that rules out provisioning hosts from list of machines
    suitable to run this VM.}
    "sched_requirements" ? string
    @{This field sets which attribute will be used to sort the suitable hosts for this VM.
    Basically, it defines which hosts are more suitable than others.}
    "sched_rank" ? string
    @{Boolean expression that rules out entries from the pool of datastores suitable
    to run this VM.}
    "sched_ds_requirements" ? string
    @{States which attribute will be used to sort the suitable datastores for this VM.
    Basically, it defines which datastores are more suitable than others.}
    "sched_ds_rank" ? string
};

@documentation{
Type that sets Numa topology and huge pages size for the VM.
More info:
https://docs.opennebula.io/6.6/management_and_operations/references/template.html#numa-topology-section
}
type opennebula_topology = {
    @{When you need to expose the NUMA topology to the guest, you have to set a pinning policy
    to map each virtual NUMA node’s resources (memory and vCPUs) onto the hypervisor nodes.
    OpenNebula can work with four different policies:

    CORE: each vCPU is assigned to a whole hypervisor core.
    No other threads in that core will be used. This policy can be useful to isolate
    the VM workload for security reasons.

    THREAD: each vCPU is assigned to a hypervisor CPU thread.

    SHARED: the VM is assigned to a set of the hypervisor CPUS shared by all the VM vCPUs.

    NONE: the VM is not assigned to any hypervisor CPUs.
    Access to the resources (i.e CPU time) will be limited by the CPU attribute.

    For pinned VMs the CPU (assigned hypervisor capacity) is automatically set to the vCPU number.
    No overcommitment is allowed for pinned workloads.}
    "pin_policy" ? choice('CORE', 'THREAD', 'SHARED', 'NONE')
    @{Number of sockets or NUMA nodes}
    "sockets" ? long(1..)
    @{Number of threads per core}
    "threads" ? long(1..)
    @{Number of cores per node}
    "cores" ? long(1..)
    @{Size of the hugepages (MB). If not defined no hugepages will be used.
    It should match with the hugepage size configured in the hypervisor.
    For example: "1024M"
    see: https://docs.opennebula.io/6.6/management_and_operations/host_cluster_management/numa.html}
    "hugepage_size" ? string
    @{Control whether the memory is to be mapped, shared or private}
    "memory_access" ? choice('shared', 'private')
};

type opennebula_vmtemplate = {
    @{Set the VNETs opennebula/vnet (bridges) required by each VM network interface}
    "vnet" : opennebula_vmtemplate_vnet
    @{Set the OpenNebula opennebula/datastore name for each vdx}
    "datastore" : opennebula_vmtemplate_datastore
    @{Set raw device mapping (RDM) for a specific virtual disk, for instance:
        '/system/opennebula/diskrdmpath/vdd/' = '/dev/sdf';
     will passthrough the block device to the VM as vdd disk. Disk size is ignored in this case.
     It requires a RDM datastore.
     See: https://docs.opennebula.io/6.10/open_cluster_deployment/storage_setup/dev_ds.html}
    "diskrdmpath" ? opennebula_rdm_disk
    @{Set ignoremac tree to avoid to include MAC values within AR/VM templates}
    "ignoremac" ? opennebula_ignoremac
    @{Set how many queues will be used for the communication between CPUs and virtio drivers.
    see: https://docs.opennebula.io/6.10/open_cluster_deployment/kvm_node/kvm_driver.html}
    "virtio_queues" ? long(0..)
    @{Set graphics to export VM graphical display (VNC is used by default)}
    "graphics" : string = 'VNC' with match (SELF, '^(VNC|SDL|SPICE)$')
    @{Select the cache mechanism for your disks. (by default is set to none)}
    "diskcache" ? string with match(SELF, '^(default|none|writethrough|writeback|directsync|unsafe)$')
    @{specific image mapping driver. qcow2 is not supported by Ceph storage backends}
    "diskdriver" ? string with match(SELF, '^(raw|qcow2)$')
    "permissions" ? opennebula_permissions
    @{Set pci list values to enable PCI Passthrough.
    PCI passthrough section is also generated based on /hardware/cards/<card_type>/<interface>/pci values.}
    "pci" ? opennebula_vmtemplate_pci[]
    @{labels is a list of strings to group the VMs under a given name and filter them
    in the admin and cloud views. It is also possible to include in the list
    sub-labels using a common slash: list("Name", "Name/SubName")}
    "labels" ? string[]
    "placements" ? opennebula_placements
    @{The optional memoryBacking element may contain several elements that influence
    how virtual memory pages are backed by host pages.
    hugepages: This tells the hypervisor that the guest should have its memory
    allocated using hugepages instead of the normal native page size.
    nosharepages: Instructs hypervisor to disable shared pages
    (memory merge, KSM) for this domain.
    locked: When set and supported by the hypervisor, memory pages belonging to the domain
    will be locked in hosts memory and the host will not be allowed to swap them out,
    which might be required for some workloads such as real-time. For QEMU/KVM guests,
    the memory used by the QEMU process itself will be locked too: unlike guest memory,
    this is an amount libvirt has no way of figuring out in advance, so it has to remove
    the limit on locked memory altogether. Thus, enabling this option opens up to a
    potential security risk: the host will be unable to reclaim the locked memory back
    from the guest when its running out of memory, which means a malicious guest allocating
    large amounts of locked memory could cause a denial-of-service attach on the host.}
    "memorybacking" ? string[] with is_consistent_memorybacking(SELF)
    @{Set up OpenNebula to control how VM resources are mapped onto the hypervisor ones.
    These settings will help you to fine tune the performance of VMs. In OpenNebula the virtual
    topology of a VM is defined by the number of sockets, cores and threads. We assume that a NUMA
    node or cell is equivalent to a socket.}
    "topology" ? opennebula_topology
    @{Request existing VM Group and roles.
    A VM Group defines a set of related VMs, and associated placement constraints for the VMs
    in the group. A VM Group allows you to place together (or separately) ceartain VMs
    (or VM classes, roles). VMGroups will help you to optimize the performance
    (e.g. not placing all the cpu bound VMs in the same host) or improve the fault tolerance
    (e.g. not placing all your front-ends in the same host) of your multi-VM applications.}
    "vmgroup" ? opennebula_vmtemplate_vmgroup[]
    @{Hide the KVM hypervisor from standard MSR based discovery.
    Useful to use PCI PT with some GPU cards or operating systems.
    More info: https://libvirt.org/formatdomain.html#hypervisor-features.}
    "hiddenkvm" ? boolean
    @{Use Virtual Machine Timer Management:
    https://libvirt.org/formatdomain.html#time-keeping}
    "hypervclock" ? boolean
    @{Define VM CPU overcommit ratio, by default it is disabled and set to 1, 1 CPU per VCPU:
    https://docs.opennebula.io/6.10/management_and_operations/capacity_planning/overcommitment.html
    }
    "cpuratio" : double(0..1) = 1.0
    @{The CPU model exposed to the guest. host-passthrough is the same model as the host.
    Available modes are stored in the host information and obtained through monitor (onehost show <id>).
    }
    "cpu_model" : string = "host-passthrough"
    @{Libvirt machine type.
    Check libvirt hyp capabilities for the list of available machine types (KVM_MACHINES list from "onehost show <id>").
    Required to use the new KVM machine types for RHEL>=9 (like q35 82Q35 chipset) with PCI passthrough:
    https://github.com/OpenNebula/one/issues/6492
    }
    "machine" ? string
} = dict();
