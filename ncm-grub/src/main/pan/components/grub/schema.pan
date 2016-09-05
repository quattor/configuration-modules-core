# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/grub/schema;

include {'quattor/schema'};

@{
 the crypted password can be supplied either in the password field
 OR, alternatively, within a file. this could be useful if putting the crypted
 password in the profile is undesirable. for this the file will be scanned
 and the password will be taken from the second field in a colon delimited
 line, where the first field matches the file_user parameter.
}

type type_grub_password = {
    "option"        : string with match (SELF, "^(md5|encrypted)$")
    "password"      ? string
    "enabled"       ? boolean
    "file"          ? string
    "file_user"     : string = "root"
} with {
    if (is_defined(SELF["enabled"]) && SELF["enabled"]
        && !is_defined(SELF["file"]) && !is_defined(SELF["password"])) {
            error("specify either a hashed password or file to retrieve it from.");
    };
    true;
};

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
    "password"  ?    type_grub_password
};


bind "/software/components/grub" = component_grub_type;

