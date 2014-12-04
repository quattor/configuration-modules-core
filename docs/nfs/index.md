### NAME

nfs: NCM component for NFS entries in `/etc/exports` and `/etc/fstab`

### DESCRIPTION

The _nfs_ component manages entries for NFS in the `/etc/exports` 
and the `/etc/fstab` files.

### RESOURCES

#### `/software/components/nfs/exports`

This is a list of named lists with "path" giving the export path and
"hosts" being a nlist of host/option entries where the key is the escaped host name and 
the value the export options(e.g. for "nfsclient.example.org(rw)",
key will be escape("nfsclient.example.org") and value will be 'rw').  Note that the values in "hosts"
may NOT contain embedded spaces and should not contain the enclosing '()'.  This restriction is not checked in
the schema!

If a path is listed more than once, then the last entry will be used
to generate the exports file.

#### `/software/components/nfs/mounts`

This is a list of named lists.  The named lists must include values
for "device", "mountpoint", and "fstype".  The named lists may contain
values for "options", "freq", and "passno"; the defaults being
"defaults", 0, and 0, respectively.

If is device is listed multiple times, then the last entry will be
used to generate a line in the `/etc/fstab` file.  Entries are added in
the order given in the list AFTER preexisting entries in the fstab
file.

If the mounts change, then the component will attempt to unmount any
mounts which are removed and mount any new ones.  If the options
change, then the volume will be remounted.

### NFS

"/software/components/nfs/exports" = list(
  nlist("path","/shared/path/",
        "hosts",list("server\*.example.org(no\_root\_squash)"))
);

\### If the SE is exporting its disk, mount it on the worker nodes.
"/software/components/nfs/mounts" = list(
  nlist("device","foreign.example.org:/shared/path/",
        "mountpoint","/mnt/foreign",
        "fstype","nfs",
        "options","rw")
);
