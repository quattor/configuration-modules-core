declaration template metaconfig/udev/rule_schema/schema;

include 'pan/types';

@documentation{
Schema for udev rules which consist of match or matches of key that results in
assignment or actions of matched key(s), referred as match_rule and udev_assign_rule in this schema.

match key is either dict of dict with a key and without one that has a value and an operator with 
equality check.
matched key result in action/assigment in ether dict of dict with a key or without one that has a
 value and an operator with assignment.

There could be multiple lines of rules with different matches independent of each rules.

example:
/etc/udev/rules.d/00-x710.rules

'rule/0' = dict(
    'match_rule', dict(
        'attrs', list(
            dict(
                'key', 'device',
                'operator', '==', 
                'value', '0x1572',
            ),
        ),
    ),
    'udev_assign_rule', dict(
        'run', list(
             dict(
                'operator', '+=', 
                'value', "/sbin/ethtool -s '%k' speed 10000",
            ),
        ),
    ),
);


ACTION is one of the match keys with value of add|change with '==' operator.
RUN is a matched key result of all the matched keys, ACTION, and ATTRS being matched, with value
of "/sbin/ethtool ..." and operator of '+='.

Please refer to udev(7) man page for the list of match and assignment or action
}

type udev_rule_match_operator = choice('==', '!=');

type udev_rule_assign_operator = choice('=', '+=', ':=');

type string_match_structure = {
    @{ dict of dict with string key, eg ACTION=="add|change" }
    'value' : string
    'operator' : udev_rule_match_operator
};

type dict_match_structure = {
    @{
        dict of dict with a key, eg
        dict(
            'key', 'device',
            'operator', '==', 
            'value', '0x1572',
        );
    }
    'key' : string_trimmed
    'value' : string_trimmed
    'operator' : udev_rule_match_operator
};

type string_assign_structure = {
    @{ dict of dict without key, eg RUN+="/sbin/ethtool --set-priv-flags '%k'" }
    'value' : string_trimmed
    'operator' : udev_rule_assign_operator
};

type dict_assign_structure = {
    @{
        dict of dict with a key, eg
        dict(
            'key', 'vendor',
            'operator', '=', 
            'value', '0x8086',
        );
    }
    'key' : string_trimmed
    'value' : string_trimmed
    'operator' : udev_rule_assign_operator
};

type device_match = {
    @{ list of possible matches }
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
    @{ list of possible assigment/actions }
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
    @{ udev rule consistes of match and assigment/action }
    'match_rule' ? device_match
    'udev_assign_rule': assign_keys
};

type udev_rules =  {
    @{ udev rules can be multiple in a file }
    'rule' : udev_rule[]
};


