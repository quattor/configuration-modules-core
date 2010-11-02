# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/filesystems/schema;

include {'quattor/schema'};
include {'quattor/blockdevices'};
include {'quattor/filesystems'};

type structure_component_filesystems = {
	include structure_component
	# No resources here: this component takes its configuration
	# from "/system/filesystems" and "/system/blockdevices"
};

bind "/software/components/filesystems" = structure_component_filesystems;
