${componentschema}

include 'quattor/types/component';
include 'pan/types';

type structure_aiishellfe = {
    "cachedir" ? absolute_file_path
    'ca_dir' ? absolute_file_path
    'ca_file' ? string
    "cdburl" : type_absoluteURI
    'cert_file' ? string
    'grub2_efi_kernel_root' ? string
    'grub2_efi_linux_cmd' ? string
    'key_file' ? string
    "lockdir" ? absolute_file_path
    "logfile" ? string
    "nbpdir" ? string
    "nbpdir_grub2" ? string
    "noaction" ? boolean
    "nodhcp" ? boolean
    "nonbp" ? boolean
    "noosinstall" ? boolean
    "osinstalldir" ? absolute_file_path
    "profile_format" : string = "xml"
    "profile_prefix" ? string
    "use_fqdn" : boolean = true
};

type structure_aiidhcp = {
    "dhcpconf" : absolute_file_path = "/etc/dhcpd.conf"
    "restartcmd" ? string
    "norestart" ? boolean
};

type aiiserver_component = {
    include structure_component
    @{Configures the aii-shellfe tool.}
    "aii-shellfe" : structure_aiishellfe
    @{Configures AII::DHCP and the aii-dhcp legacy tool.}
    "aii-dhcp" : structure_aiidhcp
};
