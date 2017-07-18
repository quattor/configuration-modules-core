object template simple_serverlist;

function pkg_repl = { null; };
include 'components/ntpd/config';
'/software/components/ntpd/dependencies' = null;

include 'base_serverlist_options';

prefix "/software/components/ntpd";

# restrict default nomodify
"restrictdefault/nomodify" = true;

#tinker panic 0 stepout 300
"tinker/panic" = 0;
"tinker/stepout" = 300;

#logconfig =syncstatus +sysevents
"logconfig" = list("=syncstatus", "+sysevents");

#statsdir /var/log/ntpstats/
#statistics loopstats peerstats
#filegen loopstats file loopstats type day enable
#filegen peerstats file peerstats type day enable

"statsdir" = "/var/log/ntpstats";
"statistics" = dict();
"statistics/loopstats" = true;
"statistics/peerstats" = true;
"filegen" = list();
"filegen/0" = dict();
"filegen/0/name" = "loopstats";
"filegen/0/file" = "loopstats";
"filegen/0/type" = "day";
"filegen/0/enableordisable" = "enable";
"filegen/1" = dict();
"filegen/1/name" = "peerstats";
"filegen/1/file" = "peerstats";
"filegen/1/type" = "day";
"filegen/1/enableordisable" = "enable";

"enable/stats" = true;

#disable ntp
"disable/ntp" = true;

#disable modict
"disable/monitor" = true;
