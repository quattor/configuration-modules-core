# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/symlink
#
#
#
#
############################################################

declaration template components/symlink/schema;

include 'quattor/schema';

type structure_symlink_replace_option_entry = {
    "all" ? string
    "dir" ? string
    "dirempty" ? string
    "file" ? string
    "link" ? string
    "none" ? string
};

type structure_symlink_entry = {
        "name" : string
        "target" : string
        "exists" ? boolean
        "delete" ? boolean
    "replace" ? structure_symlink_replace_option_entry
};

type structure_symlink_context_entry = {
        "name" : string
        "value" : string
};

type structure_symlink_option_entry = {
        "exists" ? boolean
    "replace" ? structure_symlink_replace_option_entry
};

type component_symlink = {
    include structure_component
        "links" ? structure_symlink_entry[]
        "context" ? structure_symlink_context_entry[]
        "options" ? structure_symlink_option_entry
};

bind "/software/components/symlink" = component_symlink;


