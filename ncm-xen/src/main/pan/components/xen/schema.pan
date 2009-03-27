# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/xen/schema;

include quattor/schema;



type xen_vdisk = {
    "type" : string # should be an enum
    "hostdevice" ? string # should be a path if such a type exists?
    "hostvol" ? string # volume on device for LVM
    "path" ? string # path on host for file VBD
    "guestdevice" : string # as seen by guest is there a type for dev entries?
    "rw" : string
    "size" ? long
    "create" ? boolean
    "access_method" ? string # e.g. "tap:aio", "phy"
};

#
# Storage of ALL Virtual Machines running on Quattor-managed machines
#
type xen_guest_map ={
    include structure_component
    #"guest_name" : string   # the guest name is the key of the named list xen_guest_map{} and is expected to be identical to the domain name
    "guest_mac"  : type_hwaddr
    "hypervisor_name" : string
};


type xen_domain_options = {

    "name"	: string
    "kernel" ? string
    "ramdisk" ? string
    "download" ? string[]
    "builder" ? string
    "memory" : long
    "cpus" ? string # string to allow regexp
    "vcpus" ? long
    "vif" ? string[] # defaults to ''?
#   "disk" ? string # e.g. [ 'phy:hda1,hda1,w' ]
    "disk" ? xen_vdisk[] # e.g. [ 'phy:hda1,hda1,w' ]
    "vtpm" ? string # e.g. [ 'instance=1,backend=0' ]
#   "dhcp" ? string
    "ip" ? string
    "bootloader" ? string
    "bootargs" ? string
    "netmask" ? type_ip
    "gateway" ? type_ip
    "hostname" ?  string # e.g. "\"vm%d\" % vmid"
    "root" ? string #  e.g. "/dev/hda1 ro"
    "nfs_server" ? type_ip  
    "nfs_root"   ? string
    "extra" ? string
    "vfb" ? string


# restart = 'onreboot' means on_poweroff = 'destroy'
#                            on_reboot   = 'restart'
#                            on_crash    = 'destroy'
# restart = 'always'   means on_poweroff = 'restart'
#                            on_reboot   = 'restart'
#                            on_crash    = 'restart'
# restart = 'never'    means on_poweroff = 'destroy'
#                            on_reboot   = 'destroy'
#                            on_crash    = 'destroy'
    "on_poweroff" ? string
    "on_reboot"   ? string
    "on_crash"    ? string

};


type xen_domain = {

    "options" : xen_domain_options
    "install_options" ? xen_domain_options
    # should this domain be automatically created?
    "auto"	      ? boolean

};

type xen_network_bridge = {
    "netdev" ? string
    "vifnum" ? long
};

type xen_network_vlan = {
    "netdev" : string
    "vlan" : long
};

type xen_network = {
    ##
    ## since you want to change the xen network, lets assume you know what you are doing
    ##
    "removeqemunetworklibvirtautostart" : boolean = true
    ##
    ## if the bridge is an empty nlist, it will assume it matches "xenbr(\d+)"
    ## and then it will use netdev=eth$1 and vifnum=$1
    ##
    "bridges" ? xen_network_bridge{}
    "vlans" ? xen_network_vlan{}
};

type component_xen_type = {
    include structure_component
    "create_filesystems" ? boolean
    "create_domains" ? boolean
    "domains" ? xen_domain{}
    "guest_map" ? xen_guest_map{}
    "network" ? xen_network
};


type "/software/components/xen" = component_xen_type;


