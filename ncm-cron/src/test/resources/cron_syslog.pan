object template cron_log;

"/software/components/cron/entries" =
  push(nlist(
    "name","test_default_log",
    "user","myspecialroot",
    "frequency", "1 2 3 4 5",
    "command", "some command"));

"/software/components/cron/entries" =
  push(nlist(
    "name","test_nolog",
    "user","root",
    "log",nlist("disable",true),
    "frequency", "* * * * *",
    "command", "some command"));

"/software/components/cron/entries" =
  push(nlist(
    "name","test_syslog",
    "user","root",
    "syslog",nlist(),
    "frequency", "* * * * *",
    "command", "some command"));

