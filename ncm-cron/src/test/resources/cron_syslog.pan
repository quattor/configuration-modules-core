object template cron_syslog;

"/software/components/cron/entries" =
  append(nlist(
    "name","test_default_log",
    "user","root",
    "frequency", "1 2 3 4 5",
    "command", "some command"));

# Check the smear boundary case.
# If smear is 0 the smear code isn't used, so we have to leave room for
# something to be smeared. Hence set the minutes to zero but everything else
# to maximum.
"/software/components/cron/entries" =
  append(nlist(
    "name","test_smear_max_items",
    "user","root",
    "timing", nlist("minute", "0",
                    "hour", "23",
                    "day", "31",
                    "month", "12",
                    "weekday", "6",
                    "smear", 10),
    "command", "smeared command"));

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
