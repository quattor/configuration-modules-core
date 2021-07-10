unique template metaconfig/cumulus/frr;

include 'metaconfig/cumulus/schema';

bind "/software/components/metaconfig/services/{/etc/frr/frr.conf}/contents" = cumulus_frr;

prefix "/software/components/metaconfig/services/{/etc/frr/frr.conf}";
"module" = "cumulus/frr";
# daemons: reload frr
# owner/group should be frr.frr
