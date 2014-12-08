unique template metaconfig/mrtg/config;

include 'metaconfig/mrtg/schema';

bind "/software/components/metaconfig/services/{/etc/mrtg/mrtg.cfg}/contents" = mrtg_file;

prefix "/software/components/metaconfig/services/{/etc/mrtg/mrtg.cfg}";

"module" = "mrtg/main";
"mode" = 0644;
"owner" = "root";
"group" = "root";

prefix "/software/components/metaconfig/services/{/etc/mrtg/mrtg.cfg}/contents";
"HtmlDir" = "/var/www/mrtg";
"ImageDir" = "/var/www/mrtg";
"LogFormat" = "rrdtool";
"LogDir" = "/var/lib/mrtg";
"ThreshDir" = "/var/lib/mrtg";
"WorkDir" = "/var/lib/mrtg";
"LibAdd" = "/opt/rrdtool-1.4.4/lib/perl";
