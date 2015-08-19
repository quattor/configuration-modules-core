# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/fstab/schema;

include {'quattor/schema'};
include {'quattor/blockdevices'};
include {'quattor/filesystems'};

@documentation{ 
Protected mountpoints and filesystems. 
If strict protected is true, it won't change an existing entry. Non-strict only keeps it from removal.
}
type fstab_protected_entries = {
    "mounts" : string[] = list (
	    "/", "/usr", "/home", "/opt", "/var", "/var/lib", "/var/lib/rpm",
	    "/usr/bin", "/usr/sbin", "/usr/lib", "/usr/local/bin", "/usr/lib64",
	    "/bin", "/sbin", "/etc", "swap", "/proc", "/sys", "/dev/pts", "/dev/shm",
	    "/media/floppy", "/mnt/floppy", "/media/cdrecorder", "/media/cdrom",
	    "/mnt/cdrom", "/boot"
    )
    "filesystems" ? string[]
    "strict" : boolean = false
};

type structure_component_fstab = {
    include structure_component
    "protected" : fstab_protected_entries = nlist()
    "protected_mounts" ? string[] with { 
        deprecated(0, "protected_mounts property has been deprecated, protected/mounts should be used instead"); 
        true; 
    }
};

bind "/software/components/fstab" = structure_component_fstab;
