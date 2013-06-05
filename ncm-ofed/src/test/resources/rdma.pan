object template rdma;

prefix "/software/components/ofed/openib";

"config" = "/etc/rdma/rdma.conf";

"options/srp_daemon_enable" = true;
"options/ipoib_mtu" =123;

"modules/rdma_cm" = true;

"hardware/mlx4" = false;
