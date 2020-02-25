unique template metaconfig/udev/blockdev_run;

include 'metaconfig/udev/schema';

prefix "/software/components/metaconfig/services/{/etc/udev/rules.d/99-blockdevs.rules}";

"mode" = 0644;
"owner" = "root";
"group" = "root";
"module" = "udev/blockdev";

bind "/software/components/metaconfig/services/{/etc/udev/rules.d/99-blockdevs.rules}/contents/scsi_run" =
    udev_scsi_run;
bind "/software/components/metaconfig/services/{/etc/udev/rules.d/99-blockdevs.rules}/contents/dm_run" =
    udev_dm_run;
bind "/software/components/metaconfig/services/{/etc/udev/rules.d/99-blockdevs.rules}/contents/nvme_run" =
    udev_nvme_run;
