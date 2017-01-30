object template config;

include 'metaconfig/named/config';

prefix "/software/components/metaconfig/services/{/etc/named.conf}/contents";

"logging/channels/default_debug" = dict (
    "severity", "dynamic",
    "file", "data/named.run");
"logging/category" = dict();
"includes" = append("/etc/named.rfc1912.zones");
"includes" = append("/etc/another.conf");

"acls/clients" = list('127.0.0.1', '10.10.3.250', '10.10.10.250');
"acls/vsc" = list("10.10.0.0/16", "10.20.0.0/16", "10.30.0.0/16");
"acls/os" = list("10.148.0.0/16", "10.143.0.0/16", "10.141.0.0/16");

"zones/0" = dict(
    "name", "drbd",
    "class", "IN",
    "type", "master",
    "file", "hpcugent/foo/drbd.zone"
);
"zones/1" = dict(
    "name", "slave1",
    "type", "slave",
    "file", "slaves/slave1.zone",
    "masters", list("172.31.244.251", "172.31.244.250"),
);

"zones/2" = dict(
    "name", "slave2.in-addr.arpa",
    "type", "slave",
    "file", "slaves/slave2.zone",
    "masters", list("172.31.244.251", "172.31.244.250"),
);

"zones/3" = dict(
    "name", "10.10.in-addr.arpa",
    "class", "IN",
    "type", "master",
    "file", "hpcugent/bar/10.10.rev",
);

prefix "/software/components/metaconfig/services/{/etc/named.conf}/contents/options";
"dnssec-enable" = false;
"dnssec-validation" = false;

"allow-query" = list("vsc", "os", "localhost");
"allow-recursion" = list("os", "localhost");
"allow-transfer" = list();
"dnssec-lookaside" = "auto";
"blackhole" = list();
"notify-source/0/port" = 53;
"transfer-source/0/port" = 53;
"query-source/0/port" = 53;
"forward" = "only";
"forwarders" = list('127.0.0.1', '10.10.3.250', '10.10.10.250');
"allow-query" = list("clients");
"max-cache-size" = 4*1024*1024;
"empty-zones-enable" = true;
