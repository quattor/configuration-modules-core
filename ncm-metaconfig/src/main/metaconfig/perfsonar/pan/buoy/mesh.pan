unique template metaconfig/perfsonar/buoy/mesh;

include 'metaconfig/perfsonar/buoy/schema';

bind "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents" = type_owmesh;

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}";
"module" = "perfsonar/owmesh";
"daemons" = dict(
    "perfsonarbuoy_bw_master", "restart",
    "perfsonarbuoy_bw_collector", "restart",
    "perfsonarbuoy_owp_master", "restart",
    "perfsonarbuoy_owp_collector", "restart",
);
