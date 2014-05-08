unique template cron_syslog-common;
# Note that the user names are somewhat odd.
# User names are not mocked so they must exist on the system doing
# the testing. Because cronfiles on solaris are stored by user name it makes
# testing easier if there is a different file for each test, hence using a
# different user name.

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
    "user","lp",
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
    "user","bin",
    "log",nlist("disabled",true),
    "frequency", "* * * * *",
    "command", "some command"));

"/software/components/cron/entries" =
  append(nlist(
    "name","test_syslog",
    "user","nobody",
    "syslog",nlist(
        'facility', 'user',
        'level', 'notice'
    ),
    "frequency", "* * * * *",
    "command", "some command"));

"/software/components/cron/allow" = list("root");
