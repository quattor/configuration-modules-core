object template cgconfig_example2;

include 'metaconfig/cgroups/cgconfig';

prefix "/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents";
"mount/{name=scheduler}" = '/mnt/cgroups/cpu';
"mount/{name=noctrl}" = '/mnt/cgroups/noctrl';
"mount/cpu" = '/mnt/cgroups/cpu';

"/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/group/{daemons}/controllers/cpu/cpu.shares" = '1000';
"/software/components/metaconfig/services/{/etc/cgconfig.d/quattor.conf}/contents/group/{test}/controllers/{name=noctrl}" = dict();
