# ${license-info}
# ${developer-info}
# ${author-info}

unique template quattor/aii/freeipa/default;

include 'quattor/aii/freeipa/schema';

variable FREEIPA_AII_REMOVE ?= false;
variable FREEIPA_AII_DISABLE ?= true;

"/system/aii/hooks/post_reboot/" = append(dict(
    'module', FREEIPA_AII_MODULE_NAME,
     ));

bind "/system/aii/hooks" = dict with validate_aii_freeipa_hooks('post_reboot');

"/system/aii/hooks/remove/" = append(dict(
    'module', FREEIPA_AII_MODULE_NAME,
    'remove', FREEIPA_AII_REMOVE,
    'disable', FREEIPA_AII_DISABLE,
    ));

bind "/system/aii/hooks" = dict with validate_aii_freeipa_hooks('remove');
