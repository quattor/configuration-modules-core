declaration template metaconfig/rsyslog/schema;

include 'pan/types';
include 'components/accounts/functions';

@{General queue parameters}
type rsyslog_queue = {
    @{queue filename, relative to spoolDirectory}
    'filename' ? string
    @{directory used to store queue files}
    'spoolDirectory' ? absolute_file_path
    @{maximum number of messages}
    'size' ? long(0..)
    'dequeuebatchsize' ? long(0..)
    @{maximum diskspace used by all queue files}
    'maxdiskspace' ? long(0..)
    'highwatermark' ? long(0..)
    'lowwatermark' ? long(0..)
    'fulldelaymark' ? long(0..)
    'lightdelaymark' ? long(0..)
    'discardmark' ? long(0..)
    'discardseverity' ? long(0..)
    'checkpointinterval' ? long(0..)
    'syncqueuefiles' ? boolean
    'samplinginterval' ? long(0..)
    'type' ? string with match(SELF, '^(FixedArray|LinkedList|Direct|Disk)$')
    'workerthreads' ? long(0..)
    'timeoutshutdown' ? long(0..)
    'timeoutactioncompletion' ? long(0..)
    'timeoutenqueue' ? long(0..)
    'timeoutworkerthreadshutdown' ? long(0..)
    'workerthreadminimummessages' ? long(0..)
    'maxfilesize' ? long(0..)
    'saveonshutdown' ? boolean
    'dequeueslowdown' ? long(0..)
    'dequeuetimebegin' ? long(0..)
    'dequeuetimeend' ? long(0..)
    'samplinginterval' ? long(0..)
};

@{Global configuration queue parameters}
type rsyslog_global = {
    'action.reportSuspension' ? boolean
    'action.reportSuspensionContinuation' ? boolean
    'workDirectory' ? absolute_file_path
    'dropMsgsWithMaliciousDNSPtrRecords' ? boolean
    'localHostname' ? type_hostname
    'preserveFQDN' ? boolean
    'defaultNetstreamDriverCAFile' ? absolute_file_path
    'defaultNetstreamDriverKeyFile' ? absolute_file_path
    'defaultNetstreamDriverCertFile' ? absolute_file_path
    'debug.gnutls' ? long(0..10)
    'processInternalMessages' ? boolean
    'stdlog.channelspec' ? string
    'defaultNetstreamDriver' ? string with match(SELF, '^(gtls)$')
    'maxMessageSize' ? long(0..)
    'janitorInterval' ? long(0..)
    'debug.onShutdown' ? boolean
    'debug.logFile' ? absolute_file_path
    'net.ipprotocol' ? string with match(SELF, '^(unspecified|ipv4-only|ipv6-only)$')
    'net.aclAddHostnameOnFail' ? boolean
    'net.aclResolveHostname' ? boolean
    'net.enableDNS' ? boolean
    'net.permitACLWarning' ? boolean
    'parser.parseHostnameAndTag' ? boolean
    'parser.permitSlashInHostname' ? boolean
    'senders.keepTrack' ? boolean
    'senders.timeoutAfter' ? long(0..)
    'senders.reportGoneAway' ? boolean
    'senders.reportNew' ? boolean
    'debug.unloadModules' ? boolean
    'environment' ? string[]
};

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
    @{string type tmplate}
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
