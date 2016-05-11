object template kvmrc;

include 'components/opennebula/schema';

bind "/metaconfig/contents/kvmrc" = opennebula_kvmrc;

"/metaconfig/module" = "kvmrc";

prefix "/metaconfig/contents/kvmrc";
"qemu_protocol" = "qemu+tcp";
"force_destroy" = true;
