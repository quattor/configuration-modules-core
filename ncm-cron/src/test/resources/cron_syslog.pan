object template cron_syslog;

"/software/components/cron/entries" =
  append(nlist(
    "name","test_default_log",
    "user","root",
    "frequency", "1 2 3 4 5",
    "command", "some command"));

"/software/components/cron/entries" =
  append(nlist(
    "name","test_nolog",
    "user","root",
    "log",nlist("disabled",true),
    "frequency", "* * * * *",
    "command", "some command"));

"/software/components/cron/entries" =
  append(nlist(
    "name","test_syslog",
    "user","root",
    "syslog",nlist(
        'facility', 'user',
        'level', 'notice'
    ),
    "frequency", "* * * * *",
    "command", "some command"));

"/software/components/cron/allow" = list("root");
