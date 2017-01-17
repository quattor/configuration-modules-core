declaration template quattor/aii/opennebula/schema;

include 'pan/types';

final variable OPENNEBULA_AII_MODULE_NAME ?= 'NCM::Component::opennebula';

@documentation{ 
Function to validate all aii_opennebula hooks
}
function validate_aii_opennebula_hooks = {
    if (ARGC != 1) {
        error(format("%s: requires only one argument", FUNCTION));
    };
    
    if (! exists(SELF[ARGV[0]])) {
        error(format("%s: no %s hook found.", FUNCTION, ARGV[0]));
    };
    
    hk = SELF[ARGV[0]];
    found = false;
    ind = 0;
    foreach(i; v; hk) {
        if (exists(v['module']) && v['module'] == OPENNEBULA_AII_MODULE_NAME) {
            if (found) {
                error(format("%s: second aii_opennebula %s hook found", FUNCTION, ARGV[0]));
            } else {
                found = true;
                ind = i;
            };
        };
    };
    
    if (! found) {
        error(format("%s: no aii_opennebula %s hook found", FUNCTION, ARGV[0]));
    };
    
    if (ind != length(hk) - 1) {
        error(format("%s: aii_opennebula %s hook has to be last hook (idx %s of %s)", 
        FUNCTION, ARGV[0], ind, length(hk)));
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
        if (! exists("/system/network/interfaces/"+k)) {
            error(format("entry: %s in the vnet map is not available from /system/network/interfaces tree", k));
        };
    };
    # check if all interfaces have an entry in the map
    foreach (k; v; value("/system/network/interfaces")) {
        if ((! exists(SELF[k])) && 
            (! exists(v['type']) || # if type is missing, it's a regular ethernet interface
            (! match('^(Bridge|OVSBridge)$', v['type'])))) {
            error(format("/system/network/interfaces/%s has no entry in the vnet map", k));
        };
    };
    true;
};

type opennebula_vmtemplate_datastore = string{} with {
    # check is all entries in the map have a hardrive
    foreach (k; v; SELF) {
        if (! exists("/hardware/harddisks/"+k)) {
            error(format("/hardware/harddisks/%s has no entry in the datastores map", k));
        };
    };
    # check if all interfaces have an entry in the map
    foreach (k; v; value("/hardware/harddisks")) {
        if (! exists(SELF[k])) {
            error(format("entry: %s in the datastore map is not available from /hardware/harddisks tree", k));
        };
    };
    true;
};

@documentation{ 
Type that checks if the network interface is available from the quattor tree
}
type valid_interface_ignoremac = string with {
    if (! exists("/system/network/interfaces/"+SELF)) {
        error(format("ignoremac.interface: '%s' is not available from /system/network/interfaces tree", SELF));
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
http://docs.opennebula.org/5.0/deployment/open_cloud_host_setup/pci_passthrough.html
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
Type that sets placement constraints and preferences for the VM, valid for all hosts
More info: http://docs.opennebula.org/5.0/operation/references/template.html#placement-section
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

type opennebula_vmtemplate = {
    @{Set the VNETs opennebula/vnet (bridges) required by each VM network interface}
    "vnet" : opennebula_vmtemplate_vnet
    @{Set the OpenNebula opennebula/datastore name for each vdx}
    "datastore" : opennebula_vmtemplate_datastore
    @{Set ignoremac tree to avoid to include MAC values within AR/VM templates}
    "ignoremac" ? opennebula_ignoremac
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
    sub-labels using a common slash: list("Name", "Name/SubName")
    This feature is available since OpenNebula 5.x, below this version the change 
    does not take effect.}
    "labels" ? string[]
    "placements" ? opennebula_placements
} = dict();
