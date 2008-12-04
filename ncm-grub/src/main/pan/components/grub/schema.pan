# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/grub/schema;

include quattor/schema;

type type_kernel = {
    "kernelpath"    : string
    "kernelargs"    ? string
    "multiboot"     ? string
    "mbargs"        ? string
    "initrd"        ? string
    "title"         ? string
    "fullcontrol"   ? boolean
};

type component_grub_type = {
    include structure_component
    "prefix"    ?      string
    "args"      ?    string
    "kernels"   ?    type_kernel[]
};


type "/software/components/grub" = component_grub_type;

