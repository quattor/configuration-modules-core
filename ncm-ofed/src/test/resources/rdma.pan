object template rdma;

function pkg_repl = { null; };
include 'components/ofed/config';
"/software/components/ofed/dependencies/pre" = null;


prefix "/software/components/ofed/openib";

"config" = "/etc/rdma/rdma.conf";

"options/srp_daemon_enable" = true;

"options/ipoib_mtu" = 123;
"options/node_desc" = "myname";


"modules/rdma_cm" = true;

"hardware/mlx4" = false;
"hardware/mlx5" = true;

prefix "/software/components/ofed/opensm";
"partitions/default/properties/0/guid" = 'ALL';
"names/x0123456789abcdef" = "some hca";
