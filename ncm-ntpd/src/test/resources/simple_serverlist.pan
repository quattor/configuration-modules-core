object template simple_serverlist;

"/software/components/ntpd" = nlist();

include { 'base_serverlist_options' };

prefix "/software/components/ntpd";

# restrict default nomodify
"restrictdefault/nomodify" = true;

#tinker panic 0 stepout 300
"tinker/panic" = 0;
"tinker/stepout" = 300;

#logconfig =syncstatus +sysevents
"logconfig" = list("=syncstatus", "+sysevent");

#statsdir /var/log/ntpstats/
#statistics loopstats peerstats
#filegen loopstats file loopstats type day enable
#filegen peerstats file peerstats type day enable

"statsdir"="/var/log/ntpstats";
"statistics" = nlist();
"statistics/loopstats" = true;
"statistics/peerstats" = true;
"filegen" = list();
"filegen/0" = nlist();
"filegen/0/name" = "loopstats";
"filegen/0/file" = "loopstats";
"filegen/0/type" = "day";
"filegen/0/enableordisable" = "enable";
"filegen/1" = nlist();
"filegen/1/name" = "peerstats";
"filegen/1/file" = "peerstats";
"filegen/1/type" = "day";
"filegen/1/enableordisable" = "enable";

"enable/statistics" = true;

#disable ntp
"disable/ntp" = true;

#disable monlist
"disable/monitor" = true;
