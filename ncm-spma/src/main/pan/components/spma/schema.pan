# ${license-info}
# ${developer-info}
# ${author-info}

declaration template components/spma/schema;

include 'pan/legacy';
include 'quattor/types/component';
include 'components/spma/functions';
include 'components/spma/software';

type component_spma_common = {
    "packager" : string = "yum" with match (SELF, '^(yum|yumng|ips|apt)$') # system packager to be used
};

bind "/software/packages" = SOFTWARE_PACKAGE {} {};
bind "/software/repositories" = SOFTWARE_REPOSITORY [];
