# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/network/config-ng;

include 'components/network/config';

prefix "/software/components/network";
"ncm-module" = "network_ng";

# Add dependency that can't be added to rpm directly
prefix '/software/packages';
'NetworkManager-initscripts-updown' = dict();
