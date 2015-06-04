### DESCRIPTION

The _fstab_ component manages the mount points in a node. It is able
to manipulate the fstab, and remount filesystems as specified by the
profile. It doesn't perform any dangerous operations, such as
formatting or partitioning. If you need so, use ncm-filesystems in
addition to this component.

It doesn't remove any filesystems specified under
`/software/components/fstab/protected_mounts`.

It uses the definition of file systems described in
https://twiki.cern.ch/twiki/bin/view/FIOgroup/TsiCDBBlockDevices

### SEE ALSO

[ncm-filesystems](https://metacpan.org/pod/ncm-filesystems)
