${componentschema}

include 'quattor/types/component';

type structure_nfs_exports = {
    'path' : string
    'hosts' : string{}
};

type structure_nfs_mounts = {
    'device' : string
    'mountpoint' : string
    'fstype' : string with match(SELF, '^(nfs4?|(pan|ceph)fs|none)$')
    'options' ? string
    'freq' ? long(0..)
    'passno' ? long(0..)
};

type ${project.artifactId}_component = {
    include structure_component
    @{Configure a NFS server. In particular relevant for missing exports attribute.
      If true, missing exports forces an empty exports file and a NFS service reload.
      If false, missing exports has no effect.}
    'server' : boolean = true
    @{This is a list of dicts with "path" giving the export path and
      "hosts" being a dict of host/option entries where the key is the escaped host name and
      the value the export options(e.g. for "nfsclient.example.org(rw)",
      key will be escape("nfsclient.example.org") and value will be 'rw'.

      Note that the values in "hosts" may NOT contain embedded spaces and should not contain
      the enclosing '()'.  This restriction is not checked in the schema!

      If a path is listed more than once, then the last entry will be used
      to generate the exports file.
    }
    'exports' ? structure_nfs_exports[]
    @{This is a list of dicts with mandatory values for
      "device", "mountpoint", and "fstype".  The named lists may contain
      values for "options", "freq", and "passno". the defaults being
      "defaults", 0, and 0, respectively.

      If a device is listed multiple times, then the last entry will be
      used to generate a line in the /etc/fstab file.  Entries are added in
      the order given in the list AFTER preexisting entries in the fstab
      file.

      If the mounts change, then the component will attempt to unmount any
      mounts which are removed and mount any new ones.  If the options
      change, then the volume will be remounted.
    }
    'mounts' ? structure_nfs_mounts[]
};
