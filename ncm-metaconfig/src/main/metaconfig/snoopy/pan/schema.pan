declaration template metaconfig/snoopy/schema;

include 'pan/types';

type snoopy_filter_chain = {
    'filter' : string with match(SELF, '^(exclude_(spawns_of|uid)|only_(root|tty|uid))$')
    'arguments' ? string[]
};

type snoopy_output = string with {
    if(SELF == 'syslog') {
        deprecated(0, 'Do not use snoopy syslog output with systemd');
    };
    match(SELF, '^(dev(log|null|tty)|syslog|std(out|err)|(file|socket):/.*)$')
};

type service_snoopy = {
    'filter_chain' ? snoopy_filter_chain[]
    'message_format' ? string
    'output' ? snoopy_output
    'error_logging' ? boolean
    'syslog_facility' ? string with match(SELF, '^(LOG_)?(AUTH|AUTHPRIV|CRON|DAEMON|FTP|KERN|LOCAL[0-7]|LPR|MAIL|NEWS|SYSLOG|USER|UUCP)$')
    'syslog_ident' ? string with (! match(SELF, '\s'))
    'syslog_level' ? string with match(SELF, '^(LOG_)?(EMERG|ALERT|CRIT|ERR|WARNING|NOTICE|INFO|DEBUG)$')
};
