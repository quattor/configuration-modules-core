object template sysconfig;

include 'metaconfig/libvirtd/sysconfig';

prefix "/software/components/metaconfig/services/{/etc/sysconfig/libvirtd}/contents";
"libvirtd_config" = '/etc/libvirt/libvirtd.conf';
"libvirtd_args" = '--listen';
"krb5_ktname" = '/etc/libvirt/krb5.tab';
"qemu_audio_drv" = 'sdl';
"sdl_audiodriver" = 'pulse';
"libvirtd_nofiles_limit" = 4000;
