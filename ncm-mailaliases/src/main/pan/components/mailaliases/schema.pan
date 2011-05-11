# ${license-info}
# ${developer-info}
# ${author-info}


declaration template components/mailaliases/schema;

include {'quattor/schema'};
#include pro/declaration/email/type;

#define type component_mailaliases_type = {
#  include structure_component
#};
#
# rootmail is defined under /system/rootmail
#

type mail_user_type = {
    "recipients"  : string[] # can be also a path, e.g. /dev/null
#   "allowothers" ? boolean #not yet implemented
};

type component_mailaliases_type = {
    include structure_component
    "user" ? mail_user_type{}
};

bind "/software/components/mailaliases" = component_mailaliases_type;
