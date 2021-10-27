unique template metaconfig/cumulus/acl;

include 'metaconfig/cumulus/schema';

bind "/software/components/metaconfig/services/{/etc/cumulus/acl/policy.d/50_quattor.rules}/contents" = cumulus_acl;

prefix "/software/components/metaconfig/services/{/etc/cumulus/acl/policy.d/50_quattor.rules}";
"module" = "cumulus/acl";
# daemons: none, load with cl-acltool -i
