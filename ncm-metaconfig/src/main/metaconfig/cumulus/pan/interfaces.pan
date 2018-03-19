unique template metaconfig/cumulus/interfaces;

include 'metaconfig/cumulus/schema';

bind "/software/components/metaconfig/services/{/etc/network/interfaces}/contents" = cumulus_interfaces;

prefix "/software/components/metaconfig/services/{/etc/network/interfaces}";
"module" = "cumulus/interfaces";
# daemons: switchd? or a unit around 'ifreload -a'
