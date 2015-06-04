### DESCRIPTION

The _filesystems_ component manages the filesystems on a node. It is able
to create and remove blockdevices without restarting or
re-installing.

These filesystems will be later mounted/unmounted, and added/removed
from fstab, using ncm-fstab.

The component doesn't provide any special resources at the moment. It
just watches for changes on `/system/filesystems` and `/system/blockdevices` and
creates new filesystems, if needed.

A blockdevice is useful only for its ability to hold a
filesystem. Blockdevices with no filesystems associated will not be
created. If you want any such device, create a filesystem with
"type"="none" and "mount"=false.

#### To do list

It will also remove filesystems and blockdevices that are not listed
on the profile (or have been removed). For this to be safe, it must be
possible to specify a list of filesystems that can't be touched.

Spare drives have not been tested yet.

Resizing operations, are not yet implemented.

#### Examples

We will define a software RAID 1 composed of three disks, one volume
group named Springfield on it, and two logical volumes (Simpsons and
Flanders) on it. They will be mounted on `/Evergreen`\_Terrace/742 and
`/Evergreen`\_Terrace/740, respectively.

This is how the block devices definition looks like:

    "/system/blockdevices" = nlist (
           "physical_devs", nlist (
                   "hda", nlist ("label", "none"),
                   "hdb", nlist ("label", "none"),
                   "hdc", nlist ("label", "none")
                   ),
           ### No partitions here
           "md", nlist (
                   "md0", nlist (
                           "device_list", list (
                                   "physical_devs/hda",
                                   "physical_devs/hdb",
                                   "physical_devs/hdc"
                                   ),
                           "raid_level", "RAID1",
                           "stripe_size", 64
                           ),
                   ),
           "volume_groups", nlist (
                   "Springfield", nlist (
                           "device_list", list ("md/md0")
                           ),
                   ),
           "logical_volumes", nlist (
                   "Simpsons", nlist (
                           "size", 5*GB,
                           "volume_group", "Springfield"
                           ),
                   "Flanders", nlist (
                           "size", 4*GB,
                           "volume_group", "Springfield"
                           )
                   )
           );

And then, we can define the filesystems:

    "/system/filesystems" = list (
           nlist (
                   "mountpoint", "/EverGreenTerrace/740",
                   "block_device", "logical_volumes/Flanders",
                   "mount", true,
                   "mountopts", "defaults",
                   "type", "ext2", ### God saves from crashes, you know
                   "freq", 0,
                   "pass", 0,
                   "format", false,
                   "preserve", true
                   ),
           nlist (
                   "mountpoint", "/EverGreenTerrace/742",
                   "block_device", "logical_volumes/Simpsons",
                   "mount", true,
                   "mountopts", "defaults",
                   "type", "xfs", ### Lisa's on charge!
                   "freq", 0,
                   "pass", 0,
                   "format", false,
                   "preserve", true
                   ),
           );
