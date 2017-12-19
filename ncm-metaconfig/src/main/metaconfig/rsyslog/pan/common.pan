declaration template metaconfig/rsyslog/common;

include 'pan/types';

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
