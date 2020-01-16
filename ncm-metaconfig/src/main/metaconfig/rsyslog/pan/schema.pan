declaration template metaconfig/rsyslog/schema;

include 'pan/types';
include 'components/accounts/functions';

include 'metaconfig/rsyslog/common';
include 'metaconfig/rsyslog/inputs';
include 'metaconfig/rsyslog/actions';

type rsyslog_ruleset = {
    @{Actions, generate simple rules (ie no filters)}
    'action' ? rsyslog_action[]
    @{Per ruleset queue}
    'queue' ? rsyslog_queue
} with {
    if (is_defined(SELF['action']) && is_defined(SELF['rule'])) {
        error("Only one of action or rule supported");
    };
    if (!(is_defined(SELF['action']) || is_defined(SELF['rule']))) {
        error("One of action or rule mandatory");
    };
    true;
};

type rsyslog_module_type = {
    'input' ? rsyslog_module_input
    'action' ? rsyslog_module_action
};

type rsyslog_template = {
    @{string type template}
    'string' ? string
} with length(SELF) == 1;

type rsyslog_debug = {
    'file' ? absolute_file_path
    'level' ? long(0..2)
};

type rsyslog_service = {
    @{Named input modules}
    'input' ? rsyslog_input{}
    @{Ruleset}
    'ruleset' ? rsyslog_ruleset{}
    @{debugging}
    'debug' ? rsyslog_debug
    @{global parameters}
    'global' ? rsyslog_global
    @{main queue}
    'main_queue' ? rsyslog_queue
    @{module load parameters. By default, all input types are loaded (once).
      Modules defined here precede those. Key is input name, value is a dict with key/vaue pairs.}
    'module' ? rsyslog_module_type
    @{Named templates}
    'template' ? rsyslog_template{}
    @{Default ruleset: use this ruleset as default ruleset}
    'defaultruleset' ? string
} with {
    if (is_defined(SELF['defaultruleset']) && is_defined(SELF['ruleset'])) {
        dfrl = SELF['defaultruleset'];
        if (!is_defined(SELF['ruleset'][dfrl])) {
            error(format("Default ruleset %s must be a configured ruleset", dfrl));
        };
    };
    if (!(is_defined(SELF['input']) || (is_defined(SELF['module']) && is_defined(SELF['module']['input'])))) {
        error("At leats one input or input module must be defined");
    };
    if (is_defined(SELF['input'])) {
        foreach(name; input; SELF['input']) {
            if (is_defined(input['ruleset']) && is_defined(SELF['ruleset'])) {
                if (!is_defined(SELF['ruleset'][input['ruleset']]) ) {
                    error(format("input without known ruleset %s", input['ruleset']));
                };
            };
            if (is_defined(input['name']) && name != input['name']) {
                error(format("input name %s must match name attribute %s", name, input['name']));
            };
            if (is_defined(input['Name']) && name != input['Name']) {
                error(format("input name %s must match Name attribute %s", name, input['Name']));
            };
        };
    };
    true;
};
