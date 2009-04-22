# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/diskless_server/schema;


#this way new options cannot be declared,to be investigated
type dhcp_options_type={
    "routers" ? type_hostname
    "domain-name-servers" ? type_hostname
    "time-servers" ? type_hostname
};

type dhcp_header_type={
    "ddns_update_style" : string with match (self,'ad-hoc|interim|none')
    "unknown_clients" : string with match (self,'allow|deny')
    "use_host_decl_names" : string with match (self,'on|off')
    "log_facility" : string
    "search" ? string[]
};
 
type dhcp_type={
    "subnet" : type_hostname
    "netmask" : type_hostname
    "options" ? dhcp_options_type[]
};

# propably overkill to properly define the types, no checking seems to be made
# when we just dump the whole table...
type dhcp_clients_type={
    "bootdevice" : string
    "hardware" : type_hwaddr
    "ipnumber" : type_ip
    "nextserver" : type_ip
    "filename" : string
    "rootpath" : string
};

type pxe_type={
    "descro" ? string
    "protocol" : string with match (self,'NFS|FTP|HTTP')
    "netdev" : string
    "kernel" : string
    "image" : string
    "name" : string
    "ramdisk" : long
};

#
# soon obsolete!
#cdburl and profile prefix settings for aii
type aiiset_type={
    "cdb" : string
    "prefix" : string
    "timeout" ? long
};

type dl_nfs_type={
    "rootdiroptions" : string
    "snapshotoptions" : string
};

type component_diskless_type={
    include structure_component
    "dhcp_header" ? dhcp_header_type
    "dhcp" ? dhcp_type{}
    "nodes" ? type_hostname[]
    "pxe" ? pxe_type
    "rwfiles" ? string[]
# soon obsolete
    "aii" ? aiiset_type
# later this should become mandatory, but for the transition we make it optional
    "dl_nfs" ? dl_nfs_type
# later this should become mandatory, but for the transition we make it optional
    "dhcp_clients" ? dhcp_clients_type{}
# this is optional since in some cases the clients don't have an individual profile
    "client_profiles" ? string{}
};

function is_valid_subnet_path = {
    entry="/software/components/diskless_server/dhcp/_"+argv[0]+"/";
    if (exists(entry)){
        return(true);
    }else{
        return(false);
    };
};

function fill_dhcp_clients_list = {
    client_nodes = value("/software/components/diskless_server/nodes");
    dhcp_nodeinfo = nlist();
    dhcp_entry = nlist();
    i = first( client_nodes, k, node );
    while( i ){
        j = index( ".", node );
        if ( j != -1 ) {
            node = substr( node, 0, j );
        };
        # find the boot device of each node
        client_boot_device = get_client_boot_device(node);
        dhcp_nodeinfo["bootdevice"] = client_boot_device;
        debug("Will use boot device " + client_boot_device + " for node " + node);
        # the hardware address of the clients boot device
        dhcp_nodeinfo["hardware"] = value("//profile_" + node + "/hardware/cards/nic/" + client_boot_device + "/hwaddr");
        debug("Found HW " + dhcp_nodeinfo["hardware"] + " for node " + node);
        # the ip number of the clients boot device
        dhcp_nodeinfo["ipnumber"] = value("//profile_" + node + "/system/network/interfaces/" + client_boot_device + "/ip");
        debug("Found IP " + dhcp_nodeinfo["ipnumber"] + " for node " + node);
        # next server? That's me! (so do we really have to put this into the profile???)
        #dhcp_nodeinfo["nextserver"] = value("/system/network/hostname");
        pxe_device = value("/software/components/diskless_server/pxe/netdev");
        dhcp_nodeinfo["nextserver"] = value("/system/network/interfaces/" + pxe_device + "/ip");
        # file name 
        dhcp_nodeinfo["filename"] = "linux-install/pxelinux.0";
        # the option root-path (this we could also do in the component instead of putting it in the profile!)
        dhcp_nodeinfo["rootpath"] = dhcp_nodeinfo["nextserver"] + ":" + value("/software/components/diskless_server/pxe/image") + "/root";
        dhcp_entry[node] = dhcp_nodeinfo;
        i = next( client_nodes, k, node );
    };
    return(dhcp_entry);

};

function get_client_boot_device = {
    # 
    if ( argc != 1 ){
        error("Wrong ARGC :" + ARGC + "please specify nodename.");
    };
    node = argv[0];
    client_devices = nlist();
    nics = value("//profile_" + node + "/hardware/cards/nic");
    ok = first(nics,k,v);
    
    while(ok){
        debug("checking interface " + k);
        if( exists("//profile_" + node + "/hardware/cards/nic/"+k+"/boot") && value("//profile_" + node + "/hardware/cards/nic/"+k+"/boot") ) {
            debug("found nic " + k + " with IP " + to_string(value("//profile_" + node + "/system/network/interfaces/"+k+"/ip")));
            return (k);
        }
        else{
            debug("no boot entry found for nic " + k + ", trying next.");
            ok=next(nics,k,v);
        };
    };
};


function fill_clients_profile_url = {
	client_nodes = value("/software/components/diskless_server/nodes");
	clients_profile_url = nlist();
	i = first( client_nodes, k, node );
	while( i ){
		j = index( ".", node );
		if ( j != -1 ) {
			node = substr( node, 0, j );
		};
		debug("getting profile URL for node " + node);
		if( exists("//profile_" + node + "/software/components/ccm/profile") ){
			clients_profile_url[node] = value( "//profile_" + node + "/software/components/ccm/profile");
			debug("profile URL for node " + node + ": " + clients_profile_url[node]);
		};
		i=next(client_nodes, k, node);
	};
	return(clients_profile_url);
};


function append_dl_export_list = {
    # we might have an exports list already,
    # so we have to push the new stuff on that list
    dl_export_list = list();
    client_nodes = list();
    target_nodes = list();
    exports_entry = nlist();

    if ( exists("/software/components/diskless_server/pxe/image") ) {
        pxe_imagedir = value("/software/components/diskless_server/pxe/image");
    }
    else {
        # no info where to store the pxe images? Not much I can do
        error("append_dl_export_list: no path /software/components/diskless_server/pxe/image");
    };
    if ( !exists("/software/components/diskless_server/dl_nfs/rootdiroptions") ){
        error("append_dl_export_list: no path /software/components/diskless_server/dl_nfs/rootdiroptions");
    };
    if ( !exists("/software/components/diskless_server/dl_nfs/snapshotoptions") ){
        error("append_dl_export_list: no path /software/components/diskless_server/dl_nfs/rootdiroptions");
    };

    dl_export_list = value("/software/components/nfs/exports/");
    client_nodes = value("/software/components/diskless_server/nodes");
    #
    # the entries for the root directory
    #
    i = first( client_nodes, k, node );
    while( i ){
        target_nodes[length(target_nodes)] = node + value("/software/components/diskless_server/dl_nfs/rootdiroptions" );
        i = next( client_nodes, k, node );
    };
    # pxeos/pxeboot want the server to export the directories to himself...
    target_nodes[length(target_nodes)] = value("/system/network/hostname") + value("/software/components/diskless_server/dl_nfs/rootdiroptions" );
    exports_entry["path"] =  pxe_imagedir + "/root";
    exports_entry["hosts"] = target_nodes;
    dl_export_list[length(dl_export_list)] = exports_entry;
    #
    # the entries for the snapshot directory
    #
    target_nodes = list();
    exports_entry = nlist();
    i = first( client_nodes, k, node );
    while( i ){
        target_nodes[length(target_nodes)] = node + value("/software/components/diskless_server/dl_nfs/snapshotoptions" );
        i = next( client_nodes, k, node );
    };
    # pxeos/pxeboot want the server to export the directories to himself...
    target_nodes[length(target_nodes)] = value("/system/network/hostname") + value("/software/components/diskless_server/dl_nfs/snapshotoptions" );
    exports_entry["path"] =  pxe_imagedir + "/snapshot";
    exports_entry["hosts"] = target_nodes;
    dl_export_list[length(dl_export_list)] = exports_entry;

    return(dl_export_list);

};

type "/software/components/diskless_server" = component_diskless_type;
