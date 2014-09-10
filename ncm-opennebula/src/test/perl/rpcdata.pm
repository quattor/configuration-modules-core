# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}
=pod
=head1 rpcdata module
This module provides raw rpc data (output and exit code)
=cut
package rpcdata;


use strict;
use warnings;


our %cmds;
our %files;
my $method;

# Manage users

$method = "one.user.allocate";
$cmds{$method}{out} = "_rpc RPC answer 5";
$cmds{$method}{error} = "_rpc Error sending request method one.user.allocate args [string, lsimngar], [string, my_fancy_pass], [string, core]: [UserAllocate] Error allocating a new user. NAME is already taken by USER 5. (code 8192)";

$method = "one.user.delete";
$cmds{$method}{out} = "_rpc RPC answer 3";

$method = "one.userpool.info";
$cmds{$method}{out} = <<'EOF';
_rpc RPC answer <USER_POOL><USER><ID>0</ID><GID>0</GID><GROUPS><ID>0</ID></GROUPS><GNAME>oneadmin</GNAME><NAME>oneadmin</NAME><PASSWORD>98cd8fd8cd945cceb90f54ca2532b0fd6382db5b</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><TOKEN_PASSWORD><![CDATA[8730b37913b4fad8ed06d6d248b5c51222790f36]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>0</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><USER><ID>1</ID><GID>0</GID><GROUPS><ID>0</ID></GROUPS><GNAME>oneadmin</GNAME><NAME>serveradmin</NAME><PASSWORD>3f501388a0354dc79cd5c4998eec39b457595724</PASSWORD><AUTH_DRIVER>server_cipher</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><TOKEN_PASSWORD><![CDATA[205ca1e04934df2ac448b5e693f6aca567a5e450]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>1</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><USER><ID>3</ID><GID>1</GID><GROUPS><ID>1</ID></GROUPS><GNAME>users</GNAME><NAME>lsimngar</NAME><PASSWORD>ce29b9cb50f446a532203d8f66f59f63e259b5df</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><QUATTOR><![CDATA[1]]></QUATTOR><TOKEN_PASSWORD><![CDATA[7b82ecfa1339d585df91ddb38c64c7ec8b7c9e6d]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>3</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><USER><ID>4</ID><GID>1</GID><GROUPS><ID>1</ID></GROUPS><GNAME>users</GNAME><NAME>stdweird</NAME><PASSWORD>954f663ba92466ccdc74a605f975904f59682dbc</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><QUATTOR><![CDATA[1]]></QUATTOR><TOKEN_PASSWORD><![CDATA[7b82ecfa1339d585df91ddb38c64c7ec8b7c9e6d]]></TOKEN_PASSWORD></TEMPLATE></USER><QUOTAS><ID>4</ID><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></QUOTAS><DEFAULT_USER_QUOTAS><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></DEFAULT_USER_QUOTAS></USER_POOL>
EOF

$method = "one.user.info";
$cmds{$method}{out} = <<'EOF';
_rpc RPC answer <USER><ID>0</ID><GID>0</GID><GROUPS><ID>0</ID></GROUPS><GNAME>oneadmin</GNAME><NAME>oneadmin</NAME><PASSWORD>98cd8fd8cd945cceb90f54ca2532b0fd6382db5b</PASSWORD><AUTH_DRIVER>core</AUTH_DRIVER><ENABLED>1</ENABLED><TEMPLATE><TOKEN_PASSWORD><![CDATA[8730b37913b4fad8ed06d6d248b5c51222790f36]]></TOKEN_PASSWORD></TEMPLATE><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA><DEFAULT_USER_QUOTAS><DATASTORE_QUOTA></DATASTORE_QUOTA><NETWORK_QUOTA></NETWORK_QUOTA><VM_QUOTA></VM_QUOTA><IMAGE_QUOTA></IMAGE_QUOTA></DEFAULT_USER_QUOTAS></USER>
EOF

# Manage VNETs

$method = "one.vn.allocate";
$cmds{$method}{out} = "_rpc RPC answer 89";

$method = "one.vn.delete";
$cmds{$method}{out} = "_rpc RPC answer 88";
$cmds{$method}{error} = <<'EOF';
_rpc Error sending request method one.vn.allocate args [string, BRIDGE = "br100"
DNS = "10.141.3.250"
GATEWAY = "10.141.3.250"
NAME = "altaria.os"
NETWORK_MASK = "255.255.0.0"
TYPE = "FIXED"
QUATTOR = 1
], [int, -1]: [VirtualNetworkAllocate] Error allocating a new virtual network. NAME is already taken by NET 68. (code 8192)
EOF

$method = "";

