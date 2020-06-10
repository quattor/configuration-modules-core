object template config;

@{VLT example config}

include 'metaconfig/dellnetworking/config';

prefix "/software/components/metaconfig/services/{/dellnetworking.cfg}/contents";
"feature/auto-breakout" = false;
"hostname" = "myswitch.example.org";
"systemuser" = "passwdhash";
"ntp" = "myntp.example.com";
"nameserver" = list("dns1.domain.org", "dns2.dmoain2.org");

"pvid" = 1;
"vlanids" = list(5, 10, 11, 12, 13, 20, 100, 101, 102, 103, 200);

prefix "users/admin";
"password" = "anotherpasswdhash";
"role" = "sysadmin";
"pubkey" = "abcdef";

prefix "portgroups";
"{1/1/1}" = "25g-4x";
"{1/1/2}" = "100g-1x";

prefix "management";
"ip" = "1.2.3.4";
"mask" = 16;
"gateway" = "2.3.4.5";
"ipv6" = true;

prefix "vlt";
"id" = 1;
"discovery" = list('ethernet1/1/15', 'ethernet1/1/16');
"backup" = "169.254.1.1";
"mac" = "44:38:39:FF:00:01";
"delay" = 120;
"priority" = 10;
"mtu" = 4567;
"peerrouting" = true;

prefix "interfaces/{port-channel1}";
"description" = "leg one";
"slaves" = list("ethernet1/1/1");
"vlt" = 1;
"lacp/mode" = "passive";
"lacp/fallback" = true;
"lacp/priority" = 10000;
"lacp/fast" = false;
"lacp/timeout" = 5;
"access" = 10;
"vids" = list(5, 11, 12, 13, 20, 101, 102, 103);
"speed" = 25000;
"mtu" = 9000;
"edge" = true;

prefix "interfaces/{ethernet1/1/3}";
"description" = "one server";

prefix "interfaces/{port-channel5}";
"description" = "leg 5";
"slaves" = list("ethernet1/1/5");
"vids" = list(55, 101, 103);
"lacp/mode" = "active";

prefix "interfaces/{vlan55}";
"description" = "a vlan";
"switchport" = false;
"ip" = "1.2.3.44";
"mask" = 12;

prefix "logserver";
"ip" = "9.8.7.6";
"port" = 123;
"transport" = "udp";
"level" = "debug";

prefix "routes/0";
"subnet" = "10.11.12.0";
"mask" = 24;
"gateway" = "9.8.7.6";
prefix "routes/1";
"subnet" = "10.12.0.0";
"mask" = 16;
"gateway" = "9.8.7.5";
