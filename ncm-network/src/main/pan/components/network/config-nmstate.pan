# ${license-info}
# ${developer-info}
# ${author-info}

unique template components/network/config-nmstate;

include 'components/network/config';

prefix "/software/components/network";
"ncm-module" = "nmstate";

# Add dependency that can't be added to rpm directly
prefix '/software/packages';
'nmstate' = dict();
prefix "/system/aii/osinstall/ks";
'packages' = append("NetworkManager-config-server");
