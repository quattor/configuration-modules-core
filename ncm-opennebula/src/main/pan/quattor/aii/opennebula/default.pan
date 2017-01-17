unique template quattor/aii/opennebula/default;

include 'quattor/aii/opennebula/schema';
include 'quattor/aii/opennebula/functions';

# do not overwrite/remove templates by default
variable OPENNEBULA_AII_FORCE ?= null; 
variable OPENNEBULA_AII_ONHOLD ?= null;
variable OPENNEBULA_AII_FORCE_REMOVE ?= false;

variable MAC_PREFIX ?= '02:00';

"/system/aii/hooks/configure" = append(dict(
    'module', OPENNEBULA_AII_MODULE_NAME,
    "image", OPENNEBULA_AII_FORCE,
    "template", OPENNEBULA_AII_FORCE,
));

bind "/system/aii/hooks" = dict with validate_aii_opennebula_hooks('configure');

"/system/aii/hooks/install" = append(dict(
    'module', OPENNEBULA_AII_MODULE_NAME,
    "vm", OPENNEBULA_AII_FORCE,
    "onhold", OPENNEBULA_AII_ONHOLD,
));

bind "/system/aii/hooks" = dict with validate_aii_opennebula_hooks('install');

"/system/aii/hooks/remove" = append(dict(
    'module', OPENNEBULA_AII_MODULE_NAME,
    "image", OPENNEBULA_AII_FORCE_REMOVE,
    "template", OPENNEBULA_AII_FORCE_REMOVE,
    "vm", OPENNEBULA_AII_FORCE_REMOVE,
));

bind "/system/aii/hooks" = dict with validate_aii_opennebula_hooks('remove');

"/system/aii/hooks/post_reboot" = append(dict(
    'module', OPENNEBULA_AII_MODULE_NAME,
));

bind "/system/aii/hooks" = dict with validate_aii_opennebula_hooks('post_reboot');

# If required replace VM hwaddr using OpenNebula fashion
"/hardware/cards/nic" = if (exists(OPENNEBULA_AII_REPLACE_MAC) && exists(MAC_PREFIX)) {
    opennebula_replace_vm_mac(MAC_PREFIX);
} else {
    SELF;
};
