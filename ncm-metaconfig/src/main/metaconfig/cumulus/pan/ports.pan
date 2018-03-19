unique template metaconfig/cumulus/ports;

include 'metaconfig/cumulus/schema';

bind "/software/components/metaconfig/services/{/etc/cumulus/ports.conf}/contents" = cumulus_ports;

prefix "/software/components/metaconfig/services/{/etc/cumulus/ports.conf}";
"module" = "cumulus/ports";
# daemons: update-ports