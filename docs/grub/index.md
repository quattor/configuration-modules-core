### NAME

NCM::grub - NCM grub configuration component

### SYNOPSIS

- Configure()

    Updates the grub.conf configuration file using grubby according to a
    list of kernels described in the profile. Sets the default kernel to
    that specified in `/system/kernel/version.` Supports the use of multiboot
    loaders (most commonly used for configuration of Xen systems). Returns
    error in case of failure.

- Unconfigure()

    not available.

### RESOURCES

- `/software/components/grub/active` : boolean

    activates/deactivates the component.

- `/software/components/grub/prefix` ? string

    Prefix where kernels are found. Defaults to `/boot.` May need changes
    for other platforms (eg. `/boot/efi/EFI/redhat` when using elilo on IA64)

- `/system/kernel/version` : string

    Returns the version to be used for the default kernel.

- `/software/components/grub/fullcontrol` ? boolean

    Sets if we want a full control of the kernel arguments. The default
    is 'false'.

- `/software/components/grub/args` ? string

    Sets the arguments for the default kernel at boot time.

    If 'fullcontrol' is true then the current arguments passed to the
    kernel are substituted by the ones given in this entry. Examples:

    "/software/components/grub/args" = "apm=off"; will set apm=off for
    the default kernel, changing any previously defined arguments

    "/software/components/grub/args" = ""; will unset all kernel arguments

    If 'fulcontrol' is false then an empty or undefined value leaves the
    current arguments untouched. The removal of a current argument is done 
    by preceding the argument with a "-". Examples:

    "/software/components/grub/args" = "apm=off"; will set the apm=off for the default kernel or change a previous defined (eg apm=on) argument.

    "/software/components/grub/args" = "-apm=off root=/dev/hda1"; will remove the apm=off argument and will add/change the root device.

- `/software/components/grub/kernels` ? list

    This is a list of kernels that should have entries in the grub
    configuration file. Each kernel is described by the following entries.

- `/software/components/grub/kernels`/\[i\]/kernelpath : string

    Path to the kernel (relative to "prefix" described above).

- `/software/components/grub/kernels`/\[i\]/kernelargs ? string

    Sets the arguments for this kernel at boot time. Behaviour is as
    described above for "/software/components/grub/args".

- `/software/components/grub/kernels`/\[i\]/multiboot ? string

    Allows for setting a multiboot loader which is a generic interface
    for boot loaders and operating systems. The Xen hypervisor uses a
    multiboot loader to load guest kernels as modules. N.B. multiboot
    options are supported natively by grubby from version 4.2.0-1 on;
    for earlier versions, ncm-grub will try to configure multiboot
    itself.

- `/software/components/grub/kernels`/\[i\]/mbargs ? string

    Sets the arguments that are to be passed to a multiboot loader.
    For example, the Xen hypervisor accepts arguments for setting the
    amount of memory allocated to the Domain 0 kernel.

- `/software/components/grub/kernels`/\[i\]/initrd ? string

    Optionally set an initial ramdisk image to be loaded when booting.

- `/software/components/grub/kernels`/\[i\]/title ? string

    The title string that will be used to describe this entry in grub.conf.

- `/hardware/console` ? string

    The console settings may be defined here.

### FILES MODIFIED

The component grub modifies the following files:

- `/etc/grub.conf`

    The `/etc/grub.conf` file is modified not directly but via grubby.

### DEPENDENCIES

#### Components to be run before:

none.

#### Components to be run after:

none.

### EXAMPLES

"/software/components/grub/kernels/0" =
        nlist("kernelpath", "/vmlinuz-2.6.9-22.0.1.EL",
              "kernelargs", "ro root=LABEL=/",
              "title", "Scientific Linux 4.2 / 2.6.9",
              "initrd", "/initrd-2.6.9-22.0.1.EL.img"
);

A standard SL4 kernel with initrd image to be loaded. This configuration
produces the following entry in grub.conf:

title Scientific Linux 4.2 / 2.6.9
        kernel `/vmlinuz`-2.6.9-22.0.1.EL ro root=LABEL=/
        initrd `/initrd`-2.6.9-22.0.1.EL.img

"/software/components/grub/kernels/1" =
        nlist("multiboot", "/xen-3.0.2-2.gz",
              "mbargs", "dom0\_mem=400000",
              "title", "Xen 3 / XenLinux 2.6.16",
              "kernelpath", "/vmlinuz-2.6.16-xen3\_86.1\_rhel4.1",
              "kernelargs", "max\_loop=128 root=/dev/hda2 ro",
              "initrd", "/initrd-2.6.16-xen3\_86.1\_rhel4.1"
);

A Xen 3 hypervisor with Linux 2.6 domain 0 kernel and initrd. Produces the
following entry in grub.conf:

title Xen 3 / XenLinux 2.6.16
        kernel `/xen`-3.0.2-2.gz dom0\_mem=400000 addthis
        module `/vmlinuz`-2.6.16-xen3\_86.1\_rhel4.1 max\_loop=128 root=/dev/hda2 ro
        module `/initrd`-2.6.16-xen3\_86.1\_rhel4.1

### BUGS

none known.

S

German Cancio <German.Cancio@cern.ch>, Stephen Childs <Stephen.C>

### SEE ALSO

ncm-ncd(1)
