unique template metaconfig/perfsonar/buoy/mesh;

include 'metaconfig/perfsonar/buoy/schema';

bind "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}/contents" = type_owmesh;

prefix "/software/components/metaconfig/services/{/opt/perfsonar_ps/perfsonarbuoy_ma/etc/owmesh.conf}";
"module" = "perfsonar/owmesh";
"daemon" = list(
    "perfsonarbuoy_bw_master", 
    "perfsonarbuoy_bw_collector",
    "perfsonarbuoy_owp_master", 
    "perfsonarbuoy_owp_collector"
    );
