# ${license-info}
# ${developer-info}
# ${author-info}
# ${build-info}

declaration template components/afsclt/schema;

include 'quattor/types/component';

type component_afsclt_entry = {
    include structure_component

    "thiscell" : string         # AFS home cell
    "thesecells" ? string[]       # Cell list to authenticate to
    "settime" ? boolean        # Shall AFS client sync sys time?
    "cellservdb" ? string         # Where Master CellServDB can be found
    "afs_mount" ? string         # AFS mount point (e.g. /afs)
    "cachemount" ? string         # AFS cache location (/usr/vice/etc/cache)
    "cachesize" ? string         # AFS cache size in kB
    "enabled" : legacy_binary_affirmation_string  # Shall AFS client be active ?
    "afsd_args" ? string{}       # /etc/afsd.args values for rc.afs
};

bind "/software/components/afsclt" = component_afsclt_entry;
