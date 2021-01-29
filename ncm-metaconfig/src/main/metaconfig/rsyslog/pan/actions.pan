declaration template metaconfig/rsyslog/actions;

@{Action/output module schema configuration options}

type rsyslog_action_options = {
    'writeAllMarkMessages' ? boolean
    'execOnlyEveryNthTime' ? long(0..)
    'execOnlyEveryNthTimeout' ? long(0..)
    'execOnlyOnceEveryInterval' ? long(0..)
    'execOnlyWhenPreviousIsSuspended' ? long(0..)
    'repeatedmsgcontainsoriginalmsg' ? boolean
    'resumeRetryCount' ? long(-1..)
    'resumeInterval' ? long(0..)
    'reportSuspension' ? boolean
    'reportSuspensionContinuation' ? boolean
    'copyMsg' ? boolean
};

type rsyslog_action_common = {
    @{name (useful for debugging)}
    'name' ? string_non_whitespace
    @{action options}
    'options' ? rsyslog_action_options
};

@{output file common module and action parameters}
type rsyslog_action_file_common_module = {
    'template' ? string
    'dirCreateMode' ? long(0..)
    'fileCreateMode' ? long(0..)
    'fileOwner' ? defined_user
    'fileOwnerNum' ? long(0..)
    'fileGroup' ? defined_group
    'fileGroupNum' ? long(0..)
    'dirOwner' ? defined_user
    'dirOwnerNum' ? long(0..)
    'dirGroup' ? defined_group
    'dirGroupNum' ? long(0..)
};

type rsyslog_action_file = {
    include rsyslog_action_common
    include rsyslog_action_file_common_module
    'file' ? absolute_file_path
    'dynaFile' ? string
    'closeTimeout' ? long(0..)
    'dynaFileCacheSize' ? long(0..)
    'zipLevel' ? long(0..)
    'veryRobustZip' ? boolean
    'flushInterval' ? long(0..)
    'asyncWriting' ? boolean
    'flushOnTXEnd' ? boolean
    'ioBufferSize' ? long(0..)
    'failOnChOwnFailure' ? boolean
    'createDirs' ? boolean
    'sync' ? boolean
    'sig.provider' ? choice('ksi', 'gt', 'ksi_ls12')
    'cry.provider' ? choice('gcry')
} with {
    if (is_defined(SELF['file']) && is_defined(SELF['dynaFile'])) error('Only one of file or dynaFile may be used.');
    true;
};

type rsyslog_action_prog = {
    include rsyslog_action_common
    @{The binary (and command line options; make sure to esacpe the double quotes)}
    'binary' : string
    'hup.signal' ? choice('HUP', 'USR1', 'USR2', 'INT', 'TERM')
    'signalOnClose' ? boolean
};

type rsyslog_action_fwd = {
    include rsyslog_action_common
    'Target' : type_hostname
    'Port' ? long(0..)
    'Protocol' ? choice('udp', 'tcp')
    'NetworkNamespace' ? string
    'Device' ? string with exists("/hardware/cards/nic/" + SELF)
    'TCP_Framing' ? choice('traditional', 'octet-counted')
    'ZipLevel' ? long(0..9)
    'maxErrorMessages' ? long(0..)
    'compression.mode' ? choice('none', 'single', 'stream:always')
    'compression.stream.flushOnTXEnd' ? boolean
    'RebindInterval' ? long(0..)
    'KeepAlive' ? boolean
    'KeepAlive.Probes' ? long(0..)
    'KeepAlive.Interval' ? long(0..)
    'KeepAlive.Time' ? long(0..)
    'StreamDriver' ? string_non_whitespace
    'StreamDriverMode' ? long(0..)
    'StreamDriverAuthMode' ? choice('anon', 'x509/fingerprint', 'x509/certvalid', 'x509/name')
    'StreamDriverPermittedPeers' ? string_non_whitespace
    'ResendLastMSGOnReconnect' ? boolean
    'udp.sendToAll' ? boolean
    'udp.sendDelay' ? long(0..)
    'template' ? string
};

type rsyslog_action_kafka = {
    include rsyslog_input_common
    "Broker" ? string[] = list("localhost:9092")
    "Topic" : string
    "Key" ? string
    "DynaKey" ? choice('on', 'off')
    "DynaTopic" ? string
    "DynaTopic.Cachesize" ? long(0..)
    "Partitions.Auto" ? choice('on', 'off')
    "Partitions.number" ? long(0..)
    "Partitions.useFixed" ? long(0..)
    "errorFile" ? absolute_file_path
    "statsFile" ? absolute_file_path
    "ConfParam" ? string[]
    "TopicConfParam" ? string[]
    "Template" ? string
    "closeTimeout" ? long(0..) = 2000
    "resubmitOnFailure" ? choice('on', 'off')
    "KeepFailedMessages" ? choice('on', 'off')
    "failedMsgFile" ? absolute_file_path
};

type rsyslog_action_czmq = {
    include rsyslog_action_common
    'endpoints' ? string[]
    'socktype' ? choice('PUSH', 'PUB', 'DEALER', 'RADIO', 'CLIENT', 'SCATTER')
    'sendtimeout' ? long(0..)
    'sendhwm' ? long(0..)
    'connecttimeout' ? long(0..)
    'heartbeativl' ? long(0..)
    'heartbeattimeout' ? long(0..)
    'heartbeatttl' ? long(0..)
    'topicframe' ? boolean
    'topics' ? string[]
    'dynatopic' ? boolean
    'template' ? string
};

@{Writes emergency messages to (alll) users}
type rsyslog_action_usrmsg = {
    @{Use '*' for all users}
    'users' ? string
    'template' ? string
};

type rsyslog_action = {
    'file' ? rsyslog_action_file
    'fwd' ? rsyslog_action_fwd
    'kafka' ? rsyslog_action_kafka
    'prog' ? rsyslog_action_prog
    'czmq' ? rsyslog_action_czmq
    'usrmsg' ? rsyslog_action_usrmsg
    @{If the string is the empty string, a simple stop action is defined.
      A non-empty string is the conditional to use (if expr then stop).}
    'stop' ? string
    @{A dict with key the (escaped) filename and value a list of prifilt values.
      For each file a conditional omfile action is generated with the prifilt or'ed;
      and all files are joined in one if/elsif,.. block.
      If the oneof the elements of the prifilt list is 'stop',
      the stop action will be added after the omfile action.
      The files are sorted alphabetically, so be careful when the prifilt statements have overlap.}
    'prifile' ? string[]{}
} with length(SELF) == 1;

type rsyslog_module_file_action = {
    include rsyslog_action_file_common_module
};

type rsyslog_module_action = {
    'file' ? rsyslog_module_file_action
};
