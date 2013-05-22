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

function chkconfig_allow_combinations {
    if ( ARGC != 1 || ! is_nlist(ARGV[0]) ) {
        error(function_name + ' requires 1 nlist as argument');
    };
    service = ARGV[0];

    act_map = nlist(
        'del',list("add","on","reset"),
        'off',list("on","reset"),
        'on',list("reset"),
    );
    foreach(winact;actlist;act_map) {
        if (exists(service[winact])) {
            foreach(idx;act;actlist) {
                if (exists(service[act])) {
                    error(format("Cannot combine '%s' with '%s' (%s would win).",winact,act,winact));
                }
            }
        }
    }
    true;
};

type service_type = {
  "name"      ? string
  "add"       ? boolean
  "del"       ? boolean
  "on"        ? string
  "off"       ? string
  "reset"     ? string
  "startstop" ? boolean
} with chkconfig_allow_combinations(SELF);

type component_chkconfig_type = {
  include structure_component
  "service" : service_type{}
  "default" ? string with match (SELF, 'ignore|off')
};

bind "/software/components/chkconfig" = component_chkconfig_type;
