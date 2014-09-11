# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
=pod
=head1 rpcdata module
This module provides raw rpc data (output and exit code)
More info about ONE RPC-XML client:
http://docs.opennebula.org/4.4/integration/system_interfaces/api.html
and OpenNebula Perl module:
https://github.com/stdweird/p5-net-opennebula
=cut
package rpcdata;

use strict;
use warnings;
use XML::Simple;


our %cmds;
my $method;
my @params;

# Manage users

$method = "one.user.allocate";
@params = ("newuser", "myfancypass", "core");
$cmds{rpc_create_newuser}{params} = @params;
$cmds{rpc_create_newuser}{method} = $method;
$cmds{rpc_create_newuser}{out} = "_rpc RPC answer 5";
$cmds{rpc_create_newuser}{error} = "_rpc Error sending request method one.user.allocate args [string, lsimngar], [string, my_fancy_pass], [string, core]: [UserAllocate] Error allocating a new user. NAME is already taken by USER 5. (code 8192)";

$method = "one.user.delete";
@params = (2);
$cmds{rpc_delete_user}{params} = @params;
$cmds{rpc_delete_user}{method} = $method;
$cmds{rpc_delete_user}{out} = "_rpc RPC answer 3";

$method = "one.userpool.info";
@params = ();
$cmds{rpc_list_userspool}{params} = @params;
$cmds{rpc_list_userspool}{method} = $method;
$cmds{rpc_list_userspool}{out} = <<'EOF';
_rpc RPC answer <USER_POOL><USER><ID>0</ID><GID>0</GID><GROUPS><ID>0</ID></GROUPS><GNAME>oneadmin</GNAME><NAME>oneadmin</NAME><PASSWORD>98cd8fd8cd945cceb90f54ca2532b0fd6382db5b</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><TOKEN_PASSWORD><![CDATA[8730b37913b4fad8ed06d6d248b5c51222790f36]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>0</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><USER><ID>1</ID><GID>0</GID><GROUPS><ID>0</ID></GROUPS><GNAME>oneadmin</GNAME><NAME>serveradmin</NAME><PASSWORD>3f501388a0354dc79cd5c4998eec39b457595724</PASSWORD><AUTH_DRIVER>server_cipher</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><TOKEN_PASSWORD><![CDATA[205ca1e04934df2ac448b5e693f6aca567a5e450]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>1</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><USER><ID>3</ID><GID>1</GID><GROUPS><ID>1</ID></GROUPS><GNAME>users</GNAME><NAME>lsimngar</NAME><PASSWORD>ce29b9cb50f446a532203d8f66f59f63e259b5df</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><QUATTOR><![CDATA[1]]></QUATTOR><TOKEN_PASSWORD><![CDATA[7b82ecfa1339d585df91ddb38c64c7ec8b7c9e6d]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>3</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><USER><ID>4</ID><GID>1</GID><GROUPS><ID>1</ID></GROUPS><GNAME>users</GNAME><NAME>stdweird</NAME><PASSWORD>954f663ba92466ccdc74a605f975904f59682dbc</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><QUATTOR><![CDATA[1]]></QUATTOR><TOKEN_PASSWORD><![CDATA[7b82ecfa1339d585df91ddb38c64c7ec8b7c9e6d]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>4</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><DEFAULT_USER_QUOTAS><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></DEFAULT_USER_QUOTAS></USER_POOL>
EOF

$method = "one.user.info";
@params = (1);
$cmds{rpc_list_user}{params} = @params;
$cmds{rpc_list_user}{method} = $method;
$cmds{rpc_list_user}{out} = <<'EOF';
_rpc RPC answer <USER><ID>0</ID><GID>0</GID><GROUPS><ID>0</ID></GROUPS><GNAME>oneadmin</GNAME><NAME>oneadmin</NAME><PASSWORD>98cd8fd8cd945cceb90f54ca2532b0fd6382db5b</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><TOKEN_PASSWORD><![CDATA[8730b37913b4fad8ed06d6d248b5c51222790f36]]></TOKEN_PASSWORD></TEMPLATE><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA><DEFAULT_USER_QUOTAS><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></DEFAULT_USER_QUOTAS></USER>
EOF

# Manage VNETs

$method = "one.vn.allocate";
my $vdata = <<'EOF';
BRIDGE = "br101"
DNS = "10.141.3.250"
GATEWAY = "10.141.3.250"
NAME = "altaria.vsc"
NETWORK_MASK = "255.255.0.0"
TYPE = "FIXED"
QUATTOR = 1
EOF
@params = ($vdata, -1); 
$cmds{rpc_create_newvnet}{params} = @params;
$cmds{rpc_create_newvnet}{method} = $method;
$cmds{rpc_create_newvnet}{out} = "_rpc RPC answer 89";
$cmds{rpc_create_newvnet}{error} = <<'EOF';
_rpc Error sending request method one.vn.allocate args [string, BRIDGE = "br100"
DNS = "10.141.3.250"
GATEWAY = "10.141.3.250"
NAME = "altaria.os"
NETWORK_MASK = "255.255.0.0"
TYPE = "FIXED"
QUATTOR = 1
], [int, -1]: [VirtualNetworkAllocate] Error allocating a new virtual network. NAME is already taken by NET 68. (code 8192)
EOF

$method = "one.vn.delete";
@params = (68);
$cmds{rpc_delete_vnet}{params} = @params;
$cmds{rpc_delete_vnet}{method} = $method;
$cmds{rpc_delete_vnet}{out} = "_rpc RPC answer 68";
$cmds{rpc_delete_vnet}{error} = <<'EOF';
_rpc Error sending request method one.vn.delete args [int, 68]: [VirtualNetworkDelete] Cannot delete virtual network. Can not remove a virtual network with leases in use (code 8192)
EOF

$method = "one.vnpool.info";
@params = (-2, -1, -1);
$cmds{rpc_list_vnetspool}{params} = @params;
$cmds{rpc_list_vnetspool}{method} = $method;
$cmds{rpc_list_vnetspool}{out} = <<'EOF';
_rpc RPC answer <VNET_POOL><VNET><ID>68</ID><UID>0</UID><GID>0</GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>altaria.os</NAME><PERMISSIONS><OWNER_U>1</OWNER
_U><OWNER_M>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>0</GROUP_U><GROUP_M>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSION
S><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><TYPE>1</TYPE><BRIDGE>br100</BRIDGE><VLAN>0</VLAN><PHYDEV/><VLAN_ID/><GLOBAL_PREFIX/><SITE_PREFIX/><TOTAL_LEASES>1</TOTAL_LEASE
S><TEMPLATE><BRIDGE><![CDATA[br100]]></BRIDGE><DNS><![CDATA[10.141.3.250]]></DNS><GATEWAY><![CDATA[10.141.3.250]]></GATEWAY><NETWORK_MASK><![CDATA[255.255.0.0]]></NETWORK_MASK
><PHYDEV><![CDATA[]]></PHYDEV><QUATTOR><![CDATA[1]]></QUATTOR><VLAN><![CDATA[NO]]></VLAN><VLAN_ID><![CDATA[]]></VLAN_ID></TEMPLATE></VNET><VNET><ID>88</ID><UID>0</UID><GID>0</
GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>altaria.vsc</NAME><PERMISSIONS><OWNER_U>1</OWNER_U><OWNER_M>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>0</GROUP_U><GROUP_M
>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSIONS><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><TYPE>1</TYPE><BRIDGE>b
r101</BRIDGE><VLAN>0</VLAN><PHYDEV/><VLAN_ID/><GLOBAL_PREFIX/><SITE_PREFIX/><TOTAL_LEASES>0</TOTAL_LEASES><TEMPLATE><BRIDGE><![CDATA[br101]]></BRIDGE><DNS><![CDATA[10.141.3.25
0]]></DNS><GATEWAY><![CDATA[10.141.3.250]]></GATEWAY><NETWORK_MASK><![CDATA[255.255.0.0]]></NETWORK_MASK><PHYDEV><![CDATA[]]></PHYDEV><QUATTOR><![CDATA[1]]></QUATTOR><VLAN><![
CDATA[NO]]></VLAN><VLAN_ID><![CDATA[]]></VLAN_ID></TEMPLATE></VNET></VNET_POOL>
EOF

$method = "one.vn.info";
@params = (68);
$cmds{rpc_list_vnet}{params} = @params;
$cmds{rpc_list_vnet}{method} = $method;
$cmds{rpc_list_vnet}{out} = <<'EOF';
_rpc RPC answer <VNET><ID>68</ID><UID>0</UID><GID>0</GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>altaria.os</NAME><PERMISSIONS><OWNER_U>1</OWNER_U><OWNER_M
>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>0</GROUP_U><GROUP_M>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSIONS><CLUSTER_
ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><TYPE>1</TYPE><BRIDGE>br100</BRIDGE><VLAN>0</VLAN><PHYDEV/><VLAN_ID/><GLOBAL_PREFIX/><SITE_PREFIX/><TOTAL_LEASES>1</TOTAL_LEASES><TEMPLATE
><BRIDGE><![CDATA[br100]]></BRIDGE><DNS><![CDATA[10.141.3.250]]></DNS><GATEWAY><![CDATA[10.141.3.250]]></GATEWAY><NETWORK_MASK><![CDATA[255.255.0.0]]></NETWORK_MASK><PHYDEV><!
[CDATA[]]></PHYDEV><QUATTOR><![CDATA[1]]></QUATTOR><VLAN><![CDATA[NO]]></VLAN><VLAN_ID><![CDATA[]]></VLAN_ID></TEMPLATE><LEASES><LEASE><MAC>02:00:0a:8d:08:1e</MAC><IP>10.141.8
.30</IP><IP6_LINK>fe80::400:aff:fe8d:81e</IP6_LINK><USED>1</USED><VID>55</VID></LEASE></LEASES></VNET>
EOF


# Manage Datastores

# TODO: fix one.datastore.allocate rpc call
# It should include a int (-1 by default)
$method = "one.datastore.allocate";
my $ddata = <<'EOF';
BRIDGE_LIST = "one01.altaria.os"
CEPH_HOST = "ceph021.altaria.os ceph022.altaria.os ceph023.altaria.os"
CEPH_SECRET = "8271ce8a-385d-44d7-a228-c42de4259c5e"
CEPH_USER = "libvirt"
DATASTORE_CAPACITY_CHECK = "yes"
DISK_TYPE = "RBD"
DS_MAD = "ceph"
NAME = "ceph.altaria"
POOL_NAME = "one"
TM_MAD = "ceph"
TYPE = "IMAGE_DS"
QUATTOR = 1
EOF
@params = ($data, -1);
$cmds{rpc_create_newdatastore}{params} = @params;
$cmds{rpc_create_newdatastore}{method} = $method;
$cmds{rpc_create_newdatastore}{out} = "_rpc RPC answer 102";

$method = "one.datastore.delete";
@params = (102);
$cmds{rpc_delete_datastore}{params} = @params;
$cmds{rpc_delete_datastore}{method} = $method;
$cmds{rpc_delete_datastore}{out} = "_rpc RPC answer 102";
$cmds{rpc_delete_datastore}{error} = <<'EOF';
_rpc Error sending request method one.datastore.delete args [int, 102]: [DatastoreDelete] Cannot delete datastore. Datastore 102 is not empty. (code 8192)
EOF

$method = "one.datastorepool.info";
@params = ();
$cmds{rpc_list_datastorespool}{params} = @params;
$cmds{rpc_list_datastorespool}{method} = $method;
$cmds{rpc_list_datastorespool}{out} = <<'EOF';
_rpc RPC answer <DATASTORE_POOL><DATASTORE><ID>101</ID><UID>0</UID><GID>0</GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>ceph.altaria</NAME><PERMISSIONS><OWNER_U>1</OWNER_U><OWNER_M>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>1</GROUP_U><GROUP_M>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSIONS><DS_MAD><![CDATA[ceph]]></DS_MAD><TM_MAD><![CDATA[ceph]]></TM_MAD><BASE_PATH><![CDATA[/var/lib/one//datastores/101]]></BASE_PATH><TYPE>0</TYPE><DISK_TYPE>3</DISK_TYPE><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><TOTAL_MB>48645212</TOTAL_MB><FREE_MB>48476696</FREE_MB><USED_MB>168515</USED_MB><IMAGES><ID>30</ID><ID>37</ID></IMAGES><TEMPLATE><BASE_PATH><![CDATA[/var/lib/one//datastores/]]></BASE_PATH><BRIDGE_LIST><![CDATA[one01.altaria.os]]></BRIDGE_LIST><CEPH_HOST><![CDATA[ceph021.altaria.os ceph022.altaria.os ceph023.altaria.os]]></CEPH_HOST><CEPH_SECRET><![CDATA[8271ce8a-385d-44d7-a228-c42de4259c5e]]></CEPH_SECRET><CEPH_USER><![CDATA[libvirt]]></CEPH_USER><CLONE_TARGET><![CDATA[SELF]]></CLONE_TARGET><DATASTORE_CAPACITY_CHECK><![CDATA[yes]]></DATASTORE_CAPACITY_CHECK><DISK_TYPE><![CDATA[RBD]]></DISK_TYPE><DS_MAD><![CDATA[ceph]]></DS_MAD><LN_TARGET><![CDATA[NONE]]></LN_TARGET><POOL_NAME><![CDATA[one]]></POOL_NAME><QUATTOR><![CDATA[1]]></QUATTOR><TM_MAD><![CDATA[ceph]]></TM_MAD></TEMPLATE></DATASTORE></DATASTORE_POOL>
EOF

$method = "one.datastore.info";
@params = (101);
$cmds{rpc_list_datastore}{params} = @params;
$cmds{rpc_list_datastore}{method} = $method;
$cmds{rpc_list_datastore}{out} = <<'EOF';
_rpc RPC answer <DATASTORE><ID>101</ID><UID>0</UID><GID>0</GID><UNAME>oneadmin</UNAME><GNAME>oneadmin</GNAME><NAME>ceph.altaria</NAME><PERMISSIONS><OWNER_U>1</OWNER_U><OWNER_M>1</OWNER_M><OWNER_A>0</OWNER_A><GROUP_U>1</GROUP_U><GROUP_M>0</GROUP_M><GROUP_A>0</GROUP_A><OTHER_U>0</OTHER_U><OTHER_M>0</OTHER_M><OTHER_A>0</OTHER_A></PERMISSIONS><DS_MAD><![CDATA[ceph]]></DS_MAD><TM_MAD><![CDATA[ceph]]></TM_MAD><BASE_PATH><![CDATA[/var/lib/one//datastores/101]]></BASE_PATH><TYPE>0</TYPE><DISK_TYPE>3</DISK_TYPE><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><TOTAL_MB>48645212</TOTAL_MB><FREE_MB>48476696</FREE_MB><USED_MB>168515</USED_MB><IMAGES><ID>30</ID><ID>37</ID></IMAGES><TEMPLATE><BASE_PATH><![CDATA[/var/lib/one//datastores/]]></BASE_PATH><BRIDGE_LIST><![CDATA[one01.altaria.os]]></BRIDGE_LIST><CEPH_HOST><![CDATA[ceph021.altaria.os ceph022.altaria.os ceph023.altaria.os]]></CEPH_HOST><CEPH_SECRET><![CDATA[8271ce8a-385d-44d7-a228-c42de4259c5e]]></CEPH_SECRET><CEPH_USER><![CDATA[libvirt]]></CEPH_USER><CLONE_TARGET><![CDATA[SELF]]></CLONE_TARGET><DATASTORE_CAPACITY_CHECK><![CDATA[yes]]></DATASTORE_CAPACITY_CHECK><DISK_TYPE><![CDATA[RBD]]></DISK_TYPE><DS_MAD><![CDATA[ceph]]></DS_MAD><LN_TARGET><![CDATA[NONE]]></LN_TARGET><POOL_NAME><![CDATA[one]]></POOL_NAME><QUATTOR><![CDATA[1]]></QUATTOR><TM_MAD><![CDATA[ceph]]></TM_MAD></TEMPLATE></DATASTORE>
EOF

# Manage hosts

$method = "one.host.allocate";
@params = ("hyp102", "kvm", "kvm", "dummy", -1);
$cmds{rpc_create_newhost}{params} = @params;
$cmds{rpc_create_newhost}{method} = $method;
$cmds{rpc_create_newhost}{out} = "_rpc RPC answer 173";
$cmds{rpc_create_newhost}{error} = <<'EOF';
_rpc Error sending request method one.host.allocate args [string, hyp101], [string, kvm], [string, kvm], [string, dummy], [int, -1]: [HostAllocate] Error allocating a new host. NAME is already taken by HOST 1. (code 8192)
EOF

$method = "one.host.delete";
@params = (167);
$cmds{rpc_delete_host}{params} = @params;
$cmds{rpc_delete_host}{method} = $method;
$cmds{rpc_delete_host}{out} = "_rpc RPC answer 167";
$cmds{rpc_delete_host}{error} = <<'EOF';
_rpc Error sending request method one.host.delete args [int, 1]: [HostDelete] Cannot delete host. Can not remove a host with running VMs (code 8192)
EOF

$method = "one.hostpool.info";
@params = ();
$cmds{rpc_list_hostspool}{params} = @params;
$cmds{rpc_list_hostspool}{method} = $method;
$cmds{rpc_list_hostspool}{out} = <<'EOF';
_rpc RPC answer <HOST_POOL><HOST><ID>1</ID><NAME>hyp101</NAME><STATE>2</STATE><IM_MAD><![CDATA[kvm]]></IM_MAD><VM_MAD><![CDATA[kvm]]></VM_MAD><VN_MAD><![CDATA[dummy]]></VN_MAD><LAST_MON_TIME>1410339181</LAST_MON_TIME><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><HOST_SHARE><DISK_USAGE>0</DISK_USAGE><MEM_USAGE>524288</MEM_USAGE><CPU_USAGE>100</CPU_USAGE><MAX_DISK>117529</MAX_DISK><MAX_MEM>16433996</MAX_MEM><MAX_CPU>800</MAX_CPU><FREE_DISK>109303</FREE_DISK><FREE_MEM>14898328</FREE_MEM><FREE_CPU>793</FREE_CPU><USED_DISK>1</USED_DISK><USED_MEM>1535668</USED_MEM><USED_CPU>6</USED_CPU><RUNNING_VMS>1</RUNNING_VMS><DATASTORES></DATASTORES></HOST_SHARE><VMS><ID>55</ID></VMS><TEMPLATE><ARCH><![CDATA[x86_64]]></ARCH><CPUSPEED><![CDATA[2158]]></CPUSPEED><HOSTNAME><![CDATA[hyp101.altaria.os]]></HOSTNAME><HYPERVISOR><![CDATA[kvm]]></HYPERVISOR><MODELNAME><![CDATA[Intel(R) Xeon(R) CPU           L5420  @ 2.50GHz]]></MODELNAME><NETRX><![CDATA[163198016825]]></NETRX><NETTX><![CDATA[538319851166]]></NETTX><RESERVED_CPU><![CDATA[]]></RESERVED_CPU><RESERVED_MEM><![CDATA[]]></RESERVED_MEM><VERSION><![CDATA[4.6.2]]></VERSION></TEMPLATE></HOST><HOST><ID>167</ID><NAME>hyp102</NAME><STATE>2</STATE><IM_MAD><![CDATA[kvm]]></IM_MAD><VM_MAD><![CDATA[kvm]]></VM_MAD><VN_MAD><![CDATA[dummy]]></VN_MAD><LAST_MON_TIME>1410339186</LAST_MON_TIME><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><HOST_SHARE><DISK_USAGE>0</DISK_USAGE><MEM_USAGE>0</MEM_USAGE><CPU_USAGE>0</CPU_USAGE><MAX_DISK>117529</MAX_DISK><MAX_MEM>16433996</MAX_MEM><MAX_CPU>800</MAX_CPU><FREE_DISK>109232</FREE_DISK><FREE_MEM>15789528</FREE_MEM><FREE_CPU>800</FREE_CPU><USED_DISK>1</USED_DISK><USED_MEM>644468</USED_MEM><USED_CPU>0</USED_CPU><RUNNING_VMS>0</RUNNING_VMS><DATASTORES></DATASTORES></HOST_SHARE><VMS></VMS><TEMPLATE><ARCH><![CDATA[x86_64]]></ARCH><CPUSPEED><![CDATA[2158]]></CPUSPEED><HOSTNAME><![CDATA[hyp102.altaria.os]]></HOSTNAME><HYPERVISOR><![CDATA[kvm]]></HYPERVISOR><MODELNAME><![CDATA[Intel(R) Xeon(R) CPU           L5420  @ 2.50GHz]]></MODELNAME><NETRX><![CDATA[5883921637]]></NETRX><NETTX><![CDATA[4113222929]]></NETTX><RESERVED_CPU><![CDATA[]]></RESERVED_CPU><RESERVED_MEM><![CDATA[]]></RESERVED_MEM><VERSION><![CDATA[4.6.2]]></VERSION></TEMPLATE></HOST><HOST><ID>168</ID><NAME>hyp103</NAME><STATE>3</STATE><IM_MAD><![CDATA[kvm]]></IM_MAD><VM_MAD><![CDATA[kvm]]></VM_MAD><VN_MAD><![CDATA[dummy]]></VN_MAD><LAST_MON_TIME>1410339177</LAST_MON_TIME><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><HOST_SHARE><DISK_USAGE>0</DISK_USAGE><MEM_USAGE>0</MEM_USAGE><CPU_USAGE>0</CPU_USAGE><MAX_DISK>0</MAX_DISK><MAX_MEM>0</MAX_MEM><MAX_CPU>0</MAX_CPU><FREE_DISK>0</FREE_DISK><FREE_MEM>0</FREE_MEM><FREE_CPU>0</FREE_CPU><USED_DISK>0</USED_DISK><USED_MEM>0</USED_MEM><USED_CPU>0</USED_CPU><RUNNING_VMS>0</RUNNING_VMS><DATASTORES></DATASTORES></HOST_SHARE><VMS></VMS><TEMPLATE><ERROR><![CDATA[Wed Sep 10 10:52:57 2014 : Error monitoring Host hyp103 (168): -]]></ERROR><RESERVED_CPU><![CDATA[]]></RESERVED_CPU><RESERVED_MEM><![CDATA[]]></RESERVED_MEM></TEMPLATE></HOST><HOST><ID>169</ID><NAME>hyp104</NAME><STATE>3</STATE><IM_MAD><![CDATA[kvm]]></IM_MAD><VM_MAD><![CDATA[kvm]]></VM_MAD><VN_MAD><![CDATA[dummy]]></VN_MAD><LAST_MON_TIME>1410339177</LAST_MON_TIME><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><HOST_SHARE><DISK_USAGE>0</DISK_USAGE><MEM_USAGE>0</MEM_USAGE><CPU_USAGE>0</CPU_USAGE><MAX_DISK>0</MAX_DISK><MAX_MEM>0</MAX_MEM><MAX_CPU>0</MAX_CPU><FREE_DISK>0</FREE_DISK><FREE_MEM>0</FREE_MEM><FREE_CPU>0</FREE_CPU><USED_DISK>0</USED_DISK><USED_MEM>0</USED_MEM><USED_CPU>0</USED_CPU><RUNNING_VMS>0</RUNNING_VMS><DATASTORES></DATASTORES></HOST_SHARE><VMS></VMS><TEMPLATE><ERROR><![CDATA[Wed Sep 10 10:52:57 2014 : Error monitoring Host hyp104 (169): -]]></ERROR><RESERVED_CPU><![CDATA[]]></RESERVED_CPU><RESERVED_MEM><![CDATA[]]></RESERVED_MEM></TEMPLATE></HOST></HOST_POOL>
EOF

$method = "one.host.info";
@params = (1);
$cmds{rpc_list_host}{params} = @params;
$cmds{rpc_list_host}{method} = $method;
$cmds{rpc_list_host}{out} = <<'EOF';
_rpc RPC answer <HOST><ID>1</ID><NAME>hyp101</NAME><STATE>2</STATE><IM_MAD><![CDATA[kvm]]></IM_MAD><VM_MAD><![CDATA[kvm]]></VM_MAD><VN_MAD><![CDATA[dummy]]></VN_MAD><LAST_MON_TIME>1410339181</LAST_MON_TIME><CLUSTER_ID>-1</CLUSTER_ID><CLUSTER></CLUSTER><HOST_SHARE><DISK_USAGE>0</DISK_USAGE><MEM_USAGE>524288</MEM_USAGE><CPU_USAGE>100</CPU_USAGE><MAX_DISK>117529</MAX_DISK><MAX_MEM>16433996</MAX_MEM><MAX_CPU>800</MAX_CPU><FREE_DISK>109303</FREE_DISK><FREE_MEM>14898328</FREE_MEM><FREE_CPU>793</FREE_CPU><USED_DISK>1</USED_DISK><USED_MEM>1535668</USED_MEM><USED_CPU>6</USED_CPU><RUNNING_VMS>1</RUNNING_VMS><DATASTORES></DATASTORES></HOST_SHARE><VMS><ID>55</ID></VMS><TEMPLATE><ARCH><![CDATA[x86_64]]></ARCH><CPUSPEED><![CDATA[2158]]></CPUSPEED><HOSTNAME><![CDATA[hyp101.altaria.os]]></HOSTNAME><HYPERVISOR><![CDATA[kvm]]></HYPERVISOR><MODELNAME><![CDATA[Intel(R) Xeon(R) CPU           L5420  @ 2.50GHz]]></MODELNAME><NETRX><![CDATA[163198016825]]></NETRX><NETTX><![CDATA[538319851166]]></NETTX><RESERVED_CPU><![CDATA[]]></RESERVED_CPU><RESERVED_MEM><![CDATA[]]></RESERVED_MEM><VERSION><![CDATA[4.6.2]]></VERSION></TEMPLATE></HOST>
EOF
