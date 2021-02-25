declaration template metaconfig/rsyslog/inputs;

@{Input module schema configuration options}

type rsyslog_input_common = {
    @{Bind this input to ruleset}
    'ruleset' ? string
    @{Per input queue}
    'queue' ? rsyslog_queue
};

type rsyslog_input_file = {
    include rsyslog_input_common
    @{The file being monitored. Should be an absolute name,
      but it supports wildcards}
    'File' : string
    @{Tag to use for messages that originate from this file}
    'Tag' : string
    'Facility' ? string
    'Severity' ? string
    'PersistStateInterval' ? long(0..)
    'startmsg.regex' ? string
    'readTimeout' ? long(0..)
    'readMode' ? long(0..2)
    'escapeLF' ? boolean
    'MaxLinesAtOnce' ? long(0..)
    'MaxSubmitAtOnce' ? long(0..)
    'deleteStateOnFileDelete' ? boolean
    'addMetadata' ? boolean
    'stateFile' ? absolute_file_path
    'reopenOnTruncate' ? boolean
    'trimLineOverBytes' ? long(0..)
    'freshStartTail' ? boolean
} with {
    if (is_defined(SELF['startmsg.regex']) && is_defined(SELF['readMode'])) {
        error("file input cannot have both startmsg.regex and readMode");
    };
    true;
};

type rsyslog_input_tcp = {
    include rsyslog_input_common
    @{Listen om port}
    'Port' : long(0..)
    @{Bind on interface}
    'address' ? type_hostname
    @{Srt name for inputproperty}
    'Name' ? string
    'SupportOctetCountedFraming' ? boolean
    'RateLimit.Interval' ? long(0..)
    'RateLimit.Burst' ? long(0..)
};

type rsyslog_input_udp = {
    include rsyslog_input_common
    'Address' ? type_hostname
    'Port' ? long(0..)[]
    'Device' ? string
    'RateLimit.Interval' ? long(0..)
    'RateLimit.Burst' ? long(0..)
    'name' ? string
    'InputName' ? string with {deprecated(0, "use 'name' attribute"); true; }
    'name.appendPort' ? boolean
    'InputName.AppendPort' ? boolean with {deprecated(0, "use 'name.appendPort' attribute"); true; }
    'defaultTZ' ? string
    'rcvbufSize' ? long(0..)
};

type rsyslog_input_czmq = {
    include rsyslog_input_common
    'endpoints' ? string[]
    'socktype' ? string with match(SELF, '^(PULL|SUB|ROUTER|DISH|SERVER)$')
    'authtype' ? string with mathc(SELF, '^(CURVESERVER|CURVECLIENT)$')
};

type rsyslog_input_kafka = {
    include rsyslog_input_common
    'broker': string[]
    'topic': string
    'consumergroup' ? string
    'ParseHostname' ? string with match(SELF, '^(on|off)$')
};

type rsyslog_input_uxsock = {
    include rsyslog_input_common
    'IgnoreTimestamp' ? boolean
    'IgnoreOwnMessages' ? boolean
    'FlowControl' ? boolean
    'RateLimit.Interval' ? long(0..)
    'RateLimit.Burst' ? long(0..)
    'RateLimit.Severity' ? long(0..)
    'UsePIDFromSystem' ? boolean
    'UseSysTimeStamp' ? boolean
    'CreatePath' ? boolean
    'Socket' ? string
    'HostName' ? type_hostname
    'Annotate' ? boolean
    'ParseTrusted' ? boolean
    'Unlink' ? boolean
    'useSpecialParser' ? boolean
    'parseHostname' ? boolean
};

type rsyslog_input = {
    'file' ? rsyslog_input_file
    'tcp' ? rsyslog_input_tcp
    'udp' ? rsyslog_input_udp
    'czmq' ? rsyslog_input_czmq
    'kafka' ? rsyslog_input_kafka
    'uxsock' ? rsyslog_input_uxsock
} with length(SELF) == 1;


type rsyslog_module_file = {
    'mode' ? string with match(SELF, '^(inotify|polling)$')
    'readTimeout' ? long(0..)
    'timeoutGranularity' ? long(0..)
    'PollingInterval' ? long(0..)
};

type rsyslog_module_tcp = {
    'AddtlFrameDelimiter' ? string
    'DisableLFDelimiter' ? boolean
    'maxFrameSize' ? long(0..)
    'NotifyOnConnectionClose' ? boolean
    'KeepAlive' ? boolean
    'KeepAlive.Probes' ? long(0..)
    'KeepAlive.Interval' ? long(0..)
    'KeepAlive.Time' ? long(0..)
    'FlowControl' ? boolean
    'MaxListeners' ? long(0..)
    'MaxSessions' ? long(0..)
    'StreamDriver.Name' ? string
    'StreamDriver.Mode' ? long(0..)
    'StreamDriver.AuthMode' ? string
    'PermittedPeer' ? type_hostname[]
    'discardTruncatedMsg' ? boolean
};

type rsyslog_module_udp = {
    'TimeRequery' ? long(0..)
    'SchedulingPolicy' ? string with match(SELF, '^(rr|fifo)$')
    'SchedulingPriority' ? long(0..)
    'batchSize' ? long(0..)
    'threads' ? long(0..32)
};

type rsyslog_module_czmq = {
    'servercertpath' ? absolute_file_path
    'clientcertpath' ? absolute_file_path
    'authtype' ? string with mathc(SELF, '^(CURVESERVER|CURVECLIENT)$')
    'authenticator' ? boolean
};

type rsyslog_module_uxsock = {
    'SysSock.IgnoreTimestamp' ? boolean
    'SysSock.IgnoreOwnMessages' ? boolean
    'SysSock.Use' ? boolean
    'SysSock.Name' ? string
    'SysSock.FlowControl' ? boolean
    'SysSock.UsePIDFromSystem' ? boolean
    'SysSock.RateLimit.Interval' ? long(0..)
    'SysSock.RateLimit.Burst' ? long(0..)
    'SysSock.RateLimit.Severity' ? long(0..)
    'SysSock.UseSysTimeStamp' ? boolean
    'SysSock.Annotate' ? boolean
    'SysSock.ParseTrusted' ? boolean
    'SysSock.Unlink' ? boolean
    'sysSock.useSpecialParser' ? boolean
    'sysSock.parseHostname' ? boolean
};

type rsyslog_module_mark = {
    'MarkMessagePeriod' ? long(0..)
};

type rsyslog_module_journal = {
    'PersistStateInterval' ? long(0..)
    'StateFile' ? string
    'ratelimit.interval' ? long(0..)
    'ratelimit.burst' ? long(0..)
    'IgnorePreviousMessages' ? boolean
    'DefaultSeverity' ? string
    'DefaultFacility' ? string
    'usepidfromsystem' ? boolean
    'IgnoreNonValidStatefile' ? boolean
};

type rsyslog_module_pstats = {
    'Interval' ? long(0..) = 300
    'Facility' ? long(1..9) = 5
    'Severity' ? long(1..9) = 6
    'ResetCounters' ? boolean
    'Format' ? choice('json', 'json-elasticsearch', 'legacy', 'cee') = 'legacy'
    'log.syslog' ? boolean = true
    'log.file' ? absolute_file_path
    'Bracketing' ? boolean
};

type rsyslog_module_input = {
    'file' ? rsyslog_module_file
    'tcp' ? rsyslog_module_tcp
    'udp' ? rsyslog_module_udp
    'uxsock' ? rsyslog_module_uxsock
    'mark' ? rsyslog_module_mark
    @{Using module options is not advised; use empty dict to load}
    'klog' ? dict with length(SELF) == 0
    'journal' ? rsyslog_module_journal
    'pstats' ? rsyslog_module_pstats
};
