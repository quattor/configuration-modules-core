# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/fstab/schema;

include {'quattor/schema'};
include {'quattor/blockdevices'};
include {'quattor/filesystems'};

type structure_component_fstab = {
	include structure_component
	"protected_mounts" : string[] = list (
	    "/", "/usr", "/home", "/opt", "/var", "/var/lib", "/var/lib/rpm",
	    "/usr/bin", "/usr/sbin", "/usr/lib", "/usr/local/bin", "/usr/lib64",
	    "/bin", "/sbin", "/etc", "swap", "/proc", "/sys", "/dev/pts", "/dev/shm",
	    "/media/floppy", "/mnt/floppy", "/media/cdrecorder", "/media/cdrom",
	    "/mnt/cdrom", "/boot"
	)
};

bind "/software/components/fstab" = structure_component_fstab;
