object template config;

include 'metaconfig/snoopy/config';

prefix "/software/components/metaconfig/services/{/etc/snoopy.ini}/contents";
'message_format' = '[abc %{}  eswefwerwer]';
'output' = 'socket:/some/path';
'error_logging' = true;
'syslog_facility' = 'LOG_CRON';
'syslog_ident' = 'myname';
'syslog_level' = 'EMERG';

'filter_chain' = append(dict('filter', 'only_root'));
'filter_chain' = append(dict(
    'filter', 'exclude_uid',
    'arguments', list('arg1', 'arg2'),
));
