object template config;

include 'metaconfig/rsyslog/config';

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/input";
"input1/file/queue/filename" = "input1";
"input1/file/File" = "/ab/c";
"input1/file/Tag" = "abc";

"input2/tcp/Port" = 1234;

"input3/udp/Port" = list(514, 515);

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/template";
"LOGSTASH/string" =
    '<%PRI%>1 %timegenerated:::date-rfc3339% %HOSTNAME% %syslogtag% - %APP-NAME%: %msg:::drop-last-lf%\n';

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/ruleset/rule1";
"queue/size" = 10000;
"action/0/file/zipLevel" = 2;
"action/0/file/fileCreateMode" = 0640;
"action/0/file/options/copyMsg" = true;
"action/1/prog/binary" = "some string";
"action/2/stop" = "";

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/ruleset/otherrule";
"action/0/stop" = "host != special";
"action/1/fwd/Target" = "my.hostname.domain";
"action/1/fwd/ZipLevel" = 2;
"action/2/czmq/endpoints" = list('tcp://server1/*', '*tcp://otherserver:1234');


prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/ruleset/varlog";
"action/0/prifile/{/var/log/messages}" = list(
    "*.info", "mail.none", "authpriv.none", "cron.none", "uucp.*", "news.crit"
);
"action/1/prifile/{/var/log/secure}" = list("authpriv.*", "stop");
"action/1/prifile/{/var/log/boot.log}" = list("local7.*", "stop");
"action/1/prifile/{/var/log/cron.log}" = list("cron.*", "stop");
"action/1/prifile/{/var/log/maillog}" = list("mail.*", "stop");


prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/global";
"workDirectory" = "/var/spool/rsyslog";

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/main_queue";
"filename" = "somefile";
"size" = 100;
"syncqueuefiles" = true;
"saveonshutdown" = false;

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents/module";
"input/file/mode" = "inotify";
"input/tcp/PermittedPeer" = list("host.domain", "otherhost.domain");
"input/klog" = dict();
"input/mark/MarkMessagePeriod" = 1800;
"input/pstats/Interval" = 600;
"action/file/dirCreateMode" = 0750;

prefix "/software/components/metaconfig/services/{/etc/rsyslog.conf}/contents";
"debug/file" = "/some/file";
"debug/level" = 1;
"defaultruleset" = "varlog";
