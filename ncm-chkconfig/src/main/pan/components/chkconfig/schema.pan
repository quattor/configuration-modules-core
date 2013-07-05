# ${license-info}
# ${developer-info}
# ${author-info}

############################################################
#
# type definition components/chkconfig
#
#
#
############################################################

declaration template components/chkconfig/schema;

include { 'quattor/schema' };

type service_type = {
  "name"      ? string
  "add"       ? boolean
  "del"       ? boolean
  "on"        ? string
  "off"       ? string
  "reset"     ? string
  "startstop" ? boolean
};

type component_chkconfig_type = {
  include structure_component
  "service" : service_type{}
  "default" ? string with match (SELF, 'ignore|off')
};

bind "/software/components/chkconfig" = component_chkconfig_type;
