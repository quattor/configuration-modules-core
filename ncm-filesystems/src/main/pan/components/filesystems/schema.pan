# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/filesystems/schema;

include 'quattor/schema';
include 'quattor/blockdevices';
include 'quattor/filesystems';

@documentation{
when manage_blockdevs is false, filesystems does same as fstab
No other resources here: this component takes its configuration
from fstab component, "/system/filesystems" and "/system/blockdevices"
}
type structure_component_filesystems = {
    include structure_component
    'manage_blockdevs' : boolean = true
};

bind "/software/components/filesystems" = structure_component_filesystems;
