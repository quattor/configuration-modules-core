declaration template metaconfig/udev/rule_schema/schema;

include 'pan/types';

type udev_rule_match_operator = string with match(SELF, '^(={2}|!=)$');

type udev_rule_assign_operator = string with match(SELF, '^(=|\+=|:=)$');

type string_match_structure = {
    'value' : string
    'operator' : udev_rule_match_operator
};

type dict_match_structure = {
    'key' : string
    'value' : string
    'operator' : udev_rule_match_operator
};

type string_assign_structure = {
    'value' : string
    'operator' : udev_rule_assign_operator
};

type dict_assign_structure = {
    'key' : string
    'value' : string
    'operator' : udev_rule_assign_operator
};

type device_match = {
    'action' ? string_match_structure
    'name' ? string_match_structure
    'kernel' ? string_match_structure
    'driver' ? string_match_structure
    'subsystem' ? string_match_structure
    'devpath' ? string_match_structure
    'attr' ? dict_match_structure[]
    'program' ? string_match_structure
    'result' ? string_match_structure
    'env' ? dict_match_structure[]
    'kernels' ? string_match_structure
    'drivers' ? string_match_structure
    'subsystems' ? string_match_structure
    'attrs' ? dict_match_structure[]
};

type assign_keys = {
    'name' ? string_assign_structure
    'attr' ? dict_assign_structure
    'symlink' ? string_assign_structure
    'owner' ? string_assign_structure
    'group' ? string_assign_structure
    'mode' ? string_assign_structure
    'env' ? dict_assign_structure
    'run' ? string_assign_structure[]
    'label' ? string_assign_structure
    'goto' ? string_assign_structure
    'import' ?  dict_assign_structure
    'wait_for_sysfs' ?  string_assign_structure
    'options' ?  string_assign_structure
};

type udev_rule = {
    'match_rule' ? device_match
    'udev_assign_rule': assign_keys
};

type udev_rules =  {
    'rule' : udev_rule[]
};


