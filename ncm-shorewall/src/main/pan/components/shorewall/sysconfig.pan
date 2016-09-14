unique template components/shorewall/sysconfig;

@{Create correct shorewall sysconfig file for 5.x}

include 'components/${project.artifactId}/schema';
include 'components/metaconfig/config';

prefix "/software/components/metaconfig/services/{/etc/sysconfig/shorewall}";
"module" = "tiny";
"mode" = 0644;
"daemons" = dict("shorewall", "restart");
"convert/doublequote" = true;

bind "/software/components/metaconfig/services/{/etc/sysconfig/shorewall}/contents" = shorewall_sysconfig;
