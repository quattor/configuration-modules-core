object template config;

@{VLT example config}

include 'metaconfig/dellnetworking/config';

prefix "/software/components/metaconfig/services/{/dellnetworking.cfg}/contents";
"features/0" = "auto-breakout";
"hostname" = "myswitch.example.org";
"systemuser" = "passwdhash";

"pvid" = 1;
"vlanids" = list(10, 11, 20, 100, 200);

prefix "users/admin";
"password" = "anotherpasswdhash";
"role" = "sysadmin";

prefix "portgroups";
"{1/1/1}" = "25g-4x";
"{1/1/2}" = "100g-1x";

prefix "management";
"ip" = "1.2.3.4";
"mask" = 16;
"gateway" = "2.3.4.5";

prefix "vlt";
"id" = 1;
"discovery" = list('ethernet1/1/15', 'ethernet1/1/16');
"backup" = "169.254.1.1";
"mac" = "44:38:39:FF:00:01";
"delay" = 120;

prefix "interfaces/{port-channel1}";
"description" = "leg one";
"slaves" = list("ethernet1/1/1");
"vlt" = 1;
"lacp/mode" = "passive";
"lacp/fallback" = true;
"lacp/priority" = 10000;
"access" = 10;
"vids" = list(11, 20);

prefix "interfaces/{ethernet1/1/3}";
"description" = "one server";
