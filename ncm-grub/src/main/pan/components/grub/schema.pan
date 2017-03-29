${componentschema}

include 'quattor/types/component';
include 'pan/types';

@{
 the crypted password can be supplied either in the password field
 OR, alternatively, within a file. this could be useful if putting the crypted
 password in the profile is undesirable. for this the file will be scanned
 and the password will be taken from the second field in a colon delimited
 line, where the first field matches the file_user parameter.
}

type type_grub_password = {
    @{Sets if a password should be enabled in grub.conf. If this is false,
      any existing password will be removed. If this is not defined, the component
      will not add or remove a password, leaving any existing one untouched.}
    "enabled" ? boolean
    @{An --option used with the password line in grub.conf. This is typically
      used to set the hashing algorithm for the password. "encrypted" means the
      password can be hashed with (more secure than MD5) SHA-256 or SHA-512.
      "md5" for an MD5 hashed password. Plaintext is not supported.}
    "option" : string with match (SELF, "^(md5|encrypted)$")
    @{Mutually exclusive with the file option. A crypted password for grub.conf.}
    "password" ? string
    @{Mutually exclusive with the password option. The path to a file on the host
      where the password can be read from. May be useful if it is undesirable to put
      (even crypted) profiles into the profile.

      The file will be scanned for a line where the first field (colon seperated)
      matches the file_user option, and the second field will be used as the parameter.}
    "file" ? string
    @{See description of the file option. The user (first field) to be picked from a password field.}
    "file_user" : string = "root"
} with {
    if (is_defined(SELF["enabled"]) && SELF["enabled"]
        && !is_defined(SELF["file"]) && !is_defined(SELF["password"])) {
            error("specify either a hashed password or file to retrieve it from.");
    };
    if (is_defined(SELF["file"]) && is_defined(SELF["password"])) {
        error("specify either a hashed password or file to retrieve it from, not both.");
    };
    true;
};

type type_kernel = {
    @{Path to the kernel (relative to "prefix" described above).}
    "kernelpath" : string
    @{Sets the arguments for this kernel at boot time.
      Behaviour is same as 'args' with fullcontrol false.}
    "kernelargs" ? string
    @{Allows for setting a multiboot loader which is a generic interface
     for boot loaders and operating systems. The Xen hypervisor uses a
     multiboot loader to load guest kernels as modules.}
    "multiboot" ? string
    @{Sets the arguments that are to be passed to a multiboot loader.
      For example, the Xen hypervisor accepts arguments for setting the
      amount of memory allocated to the Domain 0 kernel.}
    "mbargs" ? string
    @{Optionally set an initial ramdisk image to be loaded when booting.}
    "initrd" ? string
    @{The title string that will be used to describe this entry.}
    "title" ? string
};

type grub_component = {
    include structure_component
    @{Prefix where kernels are found. Component defaults to /boot.}
    "prefix" ? string
    @{Sets the arguments for the default kernel at boot time.
      The removal of a current argument is done by preceding the argument with a "-".

      If 'fullcontrol' is false then an empty or undefined value leaves the
      current arguments untouched.

      If 'fullcontrol' is true then the current arguments passed to the
      kernel are substituted by the ones given in this entry.}
    "args" ? string
    @{Sets if we want a full control of the kernel arguments. The component default is 'false'.}
    "fullcontrol" ? boolean
    @{This is a list of kernels that should have entries in the grub
      configuration file. Each kernel is described by the following entries.}
    "kernels" ? type_kernel[]
    "password" ? type_grub_password
};
