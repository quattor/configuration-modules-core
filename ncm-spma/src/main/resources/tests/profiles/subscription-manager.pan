object template subscription-manager;

include 'base';

# everything else has schema defaults
prefix '/software/components/spma/plugins/subscription-manager';
'enabled' = true;
'disable_system_repos' = false;
