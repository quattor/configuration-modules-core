object template blockdev_run;

include 'metaconfig/udev/blockdev_run';

prefix "/software/components/metaconfig/services/{/etc/udev/rules.d/99-blockdevs.rules}/contents";
"dm_run/0" = '/usr/lib/my_dm_script';
"scsi_run/0" = '/usr/lib/my_scsi_script';
"nvme_run/0" = '/usr/lib/my_nvme_script';
