### NAME

ncm-opennebula: Configuration module for OpenNebula

### DESCRIPTION

Configuration module for OpenNebula. 

### IMPLEMENTED FEATURES

Features that are implemented at this moment:

- oned service configuration
- Adding/removing VNETs
- Adding/removing datastores (only CEPH datastores for the moment)
- Adding/removing hypervirsors 
- Adding/removing OpenNebula regular users

OpenNebula installation is 100% automated. Therefore:

- All the new OpenNebula templates created by the component will include a QUATTOR flag
- The component only will modify/remove resources with the QUATTOR flag set, otherwise the resource is ignored
- If the component finds any issue during hypervisor host configuration then the node is included within OpenNebula infrastructure but as disabled host

### INITIAL CREATION

\- The schema details are annotated in the schema file.

\- Example pan files are included in the examples folder and also in the test folders.

To set up the initial cluster, some steps should be taken:

- 1. First install the required gems as root in your OpenNebula server: `/usr/share/one/install`\_gems
- 2. The OpenNebula server(s) should have passwordless ssh access as oneadmin user to all the hypervisor hosts of the cluster e.g. by distributing the public key(s) of the OpenNebula host over the cluster
- 3. Start OpenNebula services: ### for i in '' -econe -gate -novnc -occi -sunstone; do service opennebula$i stop; done
- 4. Run the component a first time
- 5. The new oneadmin password will be available from `/var/lib/one`/.one/one\_auth.new file

### RESOURCES

#### `/software/components/opennebula`

The configuration information for the component.  Each field should
be described in this section. 

- ssh\_multiplex : boolean

    Set ssh multiplex options

- host\_hyp : string

    Set host hypervisor type

    - kvm

        Set KVM hypervisor

    - xen

        Set XEN hypervisor

- host\_ovs : boolean (optional)

    Includes the Open vSwitch network drives in your hypervisors. (OVS must be installed in each host)
    Open vSwitch replaces Linux bridges, Linux bridges must be disabled.
    More info: http://docs.opennebula.org/4.4/administration/networking/openvswitch.html

- tm\_system\_ds : string (optional)

    Set system datastore TM\_MAD value (shared by default). Valid values:

    - shared

        The storage area for the system datastore is a shared directory across the hosts.

    - vmfs

        A specialized version of the shared one to use the vmfs file system. 

    - ssh

        Uses a local storage area from each host for the system datastore.

### DEPENDENCIES

The component was tested with OpenNebula version 4.8 and 4.10

Following package dependencies should be installed to run the component:

- perl-Config-Tiny 
- perl-LC
- perl-Net-OpenNebula >= 0.2.2 !
